#!/usr/bin/env puma

# Min and Max threads per worker
threads 1, 1

preload_app!

on_worker_boot do
  ActiveSupport.on_load(:active_record) do
    ActiveRecord::Base.establish_connection
  end
end