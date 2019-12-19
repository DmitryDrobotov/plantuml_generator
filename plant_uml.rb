require 'singleton'
require 'active_support/core_ext/string'

class Column
  FOREIGN_KEY_MATCHERS = %w(_id _type).freeze

  attr_accessor :type, :name, :options

  def initialize(type, name, **options)
    @type = type.to_sym
    @name = name
    @options = options
  end

  def foreign_key?
    FOREIGN_KEY_MATCHERS.any? do |relation_matcher|
      name.to_s.end_with?(relation_matcher)
    end
  end

  def to_plantuml
    foreign_key_mark = foreign_key? ? '*' : ''

    "#{foreign_key_mark}#{name} : #{type}"
  end
end

class Table
  SKIP_COLUMN_TYPES = %i[index]

  attr_accessor :name, :options
  attr_accessor :columns

  def initialize(name, **options)
    @name = name.to_sym
    @options = options
    @columns = []
  end

  def method_missing(column_type, *args, &block)
    # exclude next methods on table definition
    return if SKIP_COLUMN_TYPES.include?(column_type)

    column_name = args.shift
    columns << Column.new(column_type, column_name, *args)
  end

  def to_plantuml
<<-PLANTUML
entity "#{name}" as #{name} {
  id : integer <<generated>>
  --
  #{columns.map(&:to_plantuml).join("\n  ")}
}
PLANTUML
  end
end

class Relation
  attr_accessor :from_table, :to_table, :options

  def initialize(from_table, to_table, **options)
    @from_table = from_table.to_sym
    @to_table = to_table.to_sym
    @options = options
  end

  def foreign_key
    options[:column].presence || "#{to_table.to_s.singularize}_id"
  end

  def to_plantuml
    foreign_key_label = options[:column].present? ? " : #{foreign_key}" : ""

    relation_direction = [:down, :up].sample

    case relation_direction
    when :up then "#{from_table} }|--#{'-' * rand(2))} #{to_table}#{foreign_key_label}"
    when :down then "#{to_table} #{'-' * rand(2)}--|{ #{from_table}#{foreign_key_label}"
    end
  end
end

module ActiveRecord
  class Schema
    include Singleton

    attr_accessor :tables, :relations

    def self.define(info = {}, &block)
      instance.define(info, &block)
    end

    def define(info, &block) # :nodoc:
      instance_eval(&block)
    end

    def create_table(name, **options)
      return unless include_table?(name)

      table = Table.new(name, options)
      yield(table)
      tables << table
    end

    def add_foreign_key(from_table, to_table, **options)
      return if !include_table?(from_table) && !include_table?(to_table)

      relations << Relation.new(from_table, to_table, options)
    end

    def method_missing(m, *args, &block)
      puts "WARN: Missing definition ##{m}(#{args})"
    end

    def include_table?(table_name)
      return true if ARGV[1..-1].none?

      ARGV[1..-1].include?(table_name.to_s)
    end

    def to_plantuml
<<-PLANTUML
@startuml

hide circle
skinparam linetype ortho

#{tables.map(&:to_plantuml).join("\n")}

#{relations.map(&:to_plantuml).join("\n")}

@enduml
PLANTUML
    end

    private

    def initialize
      @tables = []
      @relations = []
    end
  end
end

if ARGV[0].nil?
  puts "Usage: ruby plant_uml.rb /path/to/schema.rb [table1] [table2] ..."
else
  load ARGV[0]
  puts ActiveRecord::Schema.instance.to_plantuml
end
