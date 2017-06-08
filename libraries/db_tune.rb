# Based heavily on the guidelines from this page: 
# https://wiki.postgresql.org/wiki/Tuning_Your_PostgreSQL_Server

class Chef
  class Provider 
    class DbTune < Chef::Provider::LWRPBase
      attr_reader :node, :workload

      def self.call(*args)
        new(*args).call
      end 

      def initialize(node, workload = "oltp")
        @workload = workload.to_sym
        @node = node
      end
      
      def call
        { memory: memory,
          max_connections: max_connections, 
          shared_buffers: shared_buffers,
          effective_cache_size: effective_cache_size, 
          work_memory: work_memory, 
          maintenance_work_memory: maintenance_work_memory,
          checkpoint_segments: checkpoint_segments,
          checkpoint_completion_target: checkpoint_completion_target, 
          default_statistics_target: default_statistics_target }
      end

      def max_connections
        { web: 200,
          oltp: 300,
          dw: 100,
          mixed: 150,
          desktop: 50
        }.fetch(workload)
      end

      def ohai_memory
        node['memory']['total']
      end

      def memory # in MB
        @memory ||= ohai_memory.split('kB')[0].to_i / 1024
      end

      def shared_buffers
        # The shared_buffers configuration parameter determines how much memory is dedicated 
        # to PostgreSQL to use for caching data. Use 15% if less than 1GB of memory
        # Due to binary rounding, 1GB may be represented at about 960MB

        buffers = if memory <= 950  
                    memory * 0.15
                  else 
                    { web: memory / 4,
                      oltp: memory / 4,
                      dw: memory / 4,
                      mixed: memory / 4,
                      desktop: memory / 16
                    }.fetch(workload)
                  end
        
        # Cap at 2GB for 32bit or 8GB for 64bit
        case node['kernel']['machine']
        when 'i386' # 32-bit machines max 2GB
          buffers = [buffers, 2048].min 
        when 'x86_64' # 64-bit machines max 8GB
          buffers = [buffers, 8192].min 
        end
        
        BinaryRound.call(buffers)
      end

      def effective_cache_size
        # Estimate of how much memory is available for disk caching by the operating system 
        # and within the database itself, after taking into account what's used by the OS itself 
        # and other applications

        cache = { web: memory * 3 / 4,
                  oltp: memory * 3 / 4,
                  dw: memory * 3 / 4,
                  mixed: memory * 3 / 4,
                  desktop: memory / 4
                }.fetch(workload)

        BinaryRound.call(cache)
      end

      def work_memory
        # This size is applied to each and every sort done by each user, 
        # and complex queries can use multiple working memory sort buffers.

        memory_per_connection = (memory.to_f / max_connections).ceil

        work_mem = { web: memory_per_connection,     
                     oltp: memory_per_connection,   
                     dw: memory_per_connection * 0.85      
                     mixed: memory_per_connection * 0.85,    
                     desktop: memory_per_connection * 0.15  
                   }.fetch(workload)

        BinaryRound.call(work_mem)                   
      end

      def maintenance_work_memory
        # Specifies the maximum amount of memory to be used by maintenance operations, such as VACUUM, CREATE INDEX

        maintenance_work_mem = 
          [{ web: memory / 16,
             oltp: memory / 16,
             dw: memory / 8,
             mixed: memory / 16,
             desktop: memory / 16,
           }.fetch(workload), 
           1024
          ].min

        BinaryRound.call(maintenance_work_mem) 
      end     

      def checkpoint_segments
        # PostgreSQL writes new transactions to the database in files called WAL segments 
        # that are 16MB in size. Every time checkpoint_segments worth of these files have been written, 
        # by default 3, a checkpoint occurs.

        segments =
          { web: 8,
            oltp: 16,
            dw: 64,
            mixed: 16,
            desktop: 3
          }.fetch(workload)

        if node['chef_postgres']['version'].to_f >= 9.5
          ((3 * segments) * 16).to_s + 'MB'
        else
          segments
        end
      end

      def checkpoint_completion_target
        # Time spent flushing dirty buffers during checkpoint, as fraction of the checkpoint interval.

        { web: '0.7',
          oltp: '0.9',
          dw: '0.9',
          mixed: '0.9',
          desktop: '0.5'
        }.fetch(workload)
      end
      
      def default_statistics_target
        # PG collects statistics about each of the tables in the database 
        # to decide how to execute queries against it. This helps the query planner
        # get more accurate stats. 

        { web: 100,
          oltp: 100,
          dw: 500,
          mixed: 100,
          desktop: 100
        }.fetch(workload)
      end
      
    end
  end
end
