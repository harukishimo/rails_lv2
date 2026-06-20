# frozen_string_literal: true

require "active_record/connection_adapters/sqlite3_adapter"

module RidgepoleSqliteIgnoreColumnPositionOptions
  def add_column(table_name, column_name, type, **options)
    options.delete(:after)
    options.delete(:first)

    super(table_name, column_name, type, **options)
  end
end

ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(RidgepoleSqliteIgnoreColumnPositionOptions)
