require 'singleton'

class Column
  attr_accessor :name, :type, :foreign_key

  def initialize(name, type)
    @name = name.to_sym
    @type = type.to_sym
    @foreign_key = false
  end

  def to_plantuml
    "#{'*' if foreign_key}#{name} : #{type}"
  end
end

class Table
  attr_accessor :name, :columns

  def initialize(name)
    @name = name.to_sym
    @columns = []
  end

  def method_missing(m, *args, &block)
    column_type = m

    # exclude next methods on table definition
    return if %i[index].include?(column_type)

    column_name = args[0]
    columns << Column.new(column_name, column_type)
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

module ActiveRecord
  class Schema
    include Singleton

    attr_accessor :tables

    def self.define(info = {}, &block)
      instance.define(info, &block)
    end

    def define(info, &block) # :nodoc:
      instance_eval(&block)
    end

    def create_table(name, opts = {})
      table = Table.new(name)
      yield(table)
      tables << table
    end

    def add_foreign_key(from_table, to_table, **options)
      table = tables.detect { |table| table.name == from_table.to_sym }
      search_column = (options[:column] && options[:column].to_sym) || "#{to_table[0...-1]}_id".to_sym
      column = table.columns.detect { |column| column.name == search_column }

      if column
        column.foreign_key = true
      else
        puts "WARN: Unable to find foreign key #add_foreign_key(#{from_table}, #{to_table}, #{options})"
      end
    end

    def method_missing(m, *args, &block)
      puts "WARN: Missing definition ##{m}(#{args})"
    end

    def to_plantuml
<<-PLANTUML
@startuml

hide circle
skinparam linetype ortho

#{tables.map(&:to_plantuml).join("\n\n")}

@enduml
PLANTUML
    end

    private

    def initialize
      @tables = []
    end
  end
end

if ARGV[0].nil?
  puts "Usage: ruby plant_uml.rb /path/to/schema.rb"
else
  load ARGV[0]
  puts ActiveRecord::Schema.instance.to_plantuml
end
