# frozen_string_literal: true

require "sidekiq_status/version"
require 'fileutils'
require 'sidekiq/api'

module SidekiqStatus
  class View
    CMD = File.basename($PROGRAM_NAME)
    VALID_SECTIONS = %w[all version overview processes queues].freeze

    def self.print_usage
      puts "#{CMD} - Sidekiq process stats from the command line."
      puts
      puts "Usage: #{CMD} <section>"
      puts
      puts '       <section> (optional) view a specific section of the status output'
      puts "       Valid sections are: #{VALID_SECTIONS.join(', ')}"
      puts "       Default is 'processes'"
      puts
    end

    def display(section = nil)
      section ||= 'processes'
      unless VALID_SECTIONS.include? section
      puts "Invalid section for status check: '#{section}'"
      puts "Try one of these: #{VALID_SECTIONS.join(', ')}"
      exit 1
      end
      send(section)
    rescue StandardError => e
      puts "Couldn't get status: #{e}"
      exit 1
    end

    def all
      version
      puts
      overview
      puts
      processes
      puts
      queues
    end

    def version
      puts "Sidekiq #{Sidekiq::VERSION}"
      puts Time.now.utc
    end

    def overview
      puts '---- Overview ----'
      puts "  Processed: #{delimit stats.processed}"
      puts "     Failed: #{delimit stats.failed}"
      puts "       Busy: #{delimit stats.workers_size}"
      puts "   Enqueued: #{delimit stats.enqueued}"
      puts "    Retries: #{delimit stats.retry_size}"
      puts "  Scheduled: #{delimit stats.scheduled_size}"
      puts "       Dead: #{delimit stats.dead_size}"
    end

    def processes
      puts "---- Processes (#{process_set.size}) ----"
      process_set.each_with_index do |process, index|
        puts "#{process['identity']} #{tags_for(process)}"
        puts "  Started: #{Time.at(process['started_at'])} (#{time_ago(process['started_at'])})"
        puts "  Threads: #{process['concurrency']} (#{process['busy']} busy)"
        puts "   Queues: #{split_multiline(process['queues'].sort, pad: 11)}"
        puts '' unless (index+1) == process_set.size
      end
    end

    COL_PAD = 2
    def queues
      puts "---- Queues (#{queue_data.size}) ----"
      columns = {
        name: [:ljust, (['name'] + queue_data.map(&:name)).map(&:length).max + COL_PAD],
        size: [:rjust, (['size'] + queue_data.map(&:size)).map(&:length).max + COL_PAD],
        latency: [:rjust, (['latency'] + queue_data.map(&:latency)).map(&:length).max + COL_PAD]
      }
      columns.each { |col, (dir, width)| print col.to_s.upcase.public_send(dir, width) }
      puts
      queue_data.each do |q|
        columns.each do |col, (dir, width)|
          print q.send(col).public_send(dir, width)
        end
      puts
      end
    end

    private

    def delimit(number)
      number.to_s.reverse.scan(/.{1,3}/).join(',').reverse
    end

    def split_multiline(values, opts = {})
      return 'none' unless values

      pad = opts[:pad] || 0
      max_length = opts[:max_length] || (80 - pad)
      out = []
      line = ''.dup
      values.each do |value|
      if (line.length + value.length) > max_length
        out << line
        line = ' ' * pad
      end
      line << value + ', '
      end
      out << line[0..-3]
      out.join("\n")
    end

    def tags_for(process)
      tags = [
        process['tag'],
        process['labels'],
        (process['quiet'] == 'true' ? 'quiet' : nil)
      ].flatten.compact
      tags.any? ? "[#{tags.join('] [')}]" : nil
    end

    def time_ago(timestamp)
      seconds = Time.now - Time.at(timestamp)
      return 'just now' if seconds < 60
      return 'a minute ago' if seconds < 120
      return "#{seconds.floor / 60} minutes ago" if seconds < 3600
      return 'an hour ago' if seconds < 7200

      "#{seconds.floor / 60 / 60} hours ago"
    end

    QUEUE_STRUCT = Struct.new(:name, :size, :latency)
    def queue_data
      @queue_data ||= Sidekiq::Queue.all.map do |q|
        QUEUE_STRUCT.new(q.name, q.size.to_s, sprintf('%#.2f', q.latency))
      end
    end

    def process_set
      @process_set ||= Sidekiq::ProcessSet.new
    end

    def stats
      @stats ||= Sidekiq::Stats.new
    end
  end
end
