class Szip < PACKMAN::Package
  url 'http://www.hdfgroup.org/ftp/lib-external/szip/2.1/src/szip-2.1.tar.gz'
  sha1 'd241c9acc26426a831765d660b683b853b83c131'
  version '2.1'

  def install
    if PACKMAN::OS.cygwin_gang?
      PACKMAN.replace 'src/Makefile.am', {
        /libsz_la_LDFLAGS\s*=\s*(.*)$/ => 'libsz_la_LDFLAGS = \1 -no-undefined'
      }
      PACKMAN.replace 'src/Makefile.in', {
        /libsz_la_LDFLAGS\s*=\s*(.*)$/ => 'libsz_la_LDFLAGS = \1 -no-undefined'
      }
    end
    args = %W[
      --prefix=#{PACKMAN::Package.prefix(self)}
      --disable-debug
      --disable-dependency-tracking
    ]
    PACKMAN.run('./configure', *args)
    PACKMAN.run('make install')
    if PACKMAN::OS.type == :Linux
      create_cmake_config 'SZIP', 'include', %W[libsz.a  libsz.la  libsz.so  libsz.so.2  libsz.so.2.0.0]
    end
  end
end
