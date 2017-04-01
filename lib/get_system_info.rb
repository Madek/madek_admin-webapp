# shared code for rails controller and bin/get_system_info

require 'json'

def syscall(cmd)
  begin; `#{cmd}`.chomp.strip; rescue; nil; end
end

def get_system_info
  {
    os: get_os_info,
    host: {
      hostname: syscall('hostname'),
      fqdn: syscall('hostname -f'),
      cpu: get_proc_info(:cpuinfo),
      memory: get_proc_info(:meminfo)
    }
  }
end

private

# http://www.unix.com/man-page/posix/1posix/uname
def get_os_info
  fields = %w(Name Version Architecture)
  vals = begin
    syscall('for f in s v m; do uname -$f; done').split("\n")
  rescue
    [nil, nil, nil]
  end
  fields.zip(vals).to_h
end

# https://www.kernel.org/doc/Documentation/filesystems/proc.txt
def get_proc_info(name)
  begin
    syscall("cat /proc/#{name}")
      .split("\n")
      .map do |line|
        fields = line.split("\t:")
        key = fields.shift
        [key.strip, fields.join.strip] if key
      end
      .compact
      .to_h
  rescue => e
    "ERROR #{e}"
  end
end

def read_system_info_for_rails
  fail 'Only for usage with Rails!' unless defined?(Rails)
  begin
    if Rails.env == 'test'
      JSON.parse(`cat spec/support/fixtures/system_info.json`)
    else
      get_system_info.as_json
    end
  rescue => err
    # this should NEVER break the app, but if it fails show why:
    { error: err }
  end
end
