#------------------------------------------------------------------------
# (The MIT License)
#
# Copyright (c) 2008-2011 Rhomobile, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# http://rhomobile.com
#------------------------------------------------------------------------
 VS_FIXEDFILEINFO = Struct.new("VS_FIXEDFILEINFO", :Signature, :StrucVersion, :FileVersionMS, :FileVersionLS, :ProductVersionMS, :ProductVersionLS, :FileFlagsMask, :FileFlags, :FileOS, :FileType, :FileSubtype, :FileDateMS, :FileDateLS)
 
 
def GetFileVersion(vfilename)
    require 'Win32API' 
    apiGetFileVersionInfo = Win32API.new("version", "GetFileVersionInfo",['P','L','L','P'], 'L') 
    apiGetFileVersionInfoSize = Win32API.new("version", "GetFileVersionInfoSize",['P','P'], 'L') 
    apiGetInfoFromVersion = Win32API.new("version", "VerQueryValue",['P','P','P','P'], 'L') 
    memcpy = Win32API.new('msvcrt','memcpy','PLL','P') 
    size = apiGetFileVersionInfoSize.call(vfilename,nil) 
    infoVersion = "\0" * size 
    apiGetFileVersionInfo.call(vfilename,0,size,infoVersion) 
    lplpBuffer = "\0" * 4 
    pLen = "\0" * 4 
    apiGetInfoFromVersion.call(infoVersion,"\\",lplpBuffer,pLen) 
    lpBuffer = lplpBuffer.unpack("L")[0] 
    bufSize = pLen.unpack("L*")[0] 
    rbuf = "\0" * bufSize 
    memcpy.call(rbuf,lpBuffer,bufSize) 
    vs_fixedfileinfo = VS_FIXEDFILEINFO.new(*rbuf.unpack("L*"))
    info = rbuf.unpack('LSSSSSSSSSSLLLLLLL')
    file_version = [ info[4], info[3], info[6], info[5] ]
    product_version = [ info[8], info[7], info[10], info[9] ]
    return  product_version.join(".")
end

def is_equal(minimum,current)
  m = minimum.split(".")
  c = current.split(".")
  [m.size,c.size].min.times do|e|
    next if m[e].to_i == c[e].to_i
    return m[e].to_i == c[e].to_i
  end
  return true
end

def QTInfo(qtcurrentversion)
      value =0 # default value
      
      eqstatus = is_equal("4.7.4.0",qtcurrentversion)
      puts "Checking for 4.7.4.0 - #{eqstatus}"
      if(eqstatus)
          value =1 # 4.7.4.0
      end
      
      eqstatus = is_equal("5.1.1.0",qtcurrentversion)
      puts "Checking for 5.1.1.0 - #{eqstatus}"
      if(eqstatus)
          value =2 # for 5.1.1.0
      end
      
      eqstatus = is_equal("5.5.0.0",qtcurrentversion)
      puts "Checking for 5.5.0.0 - #{eqstatus}"
       if(eqstatus)
          value =3 # 5.5.0.0
      end

      eqstatus = is_equal("5.8.0.0",qtcurrentversion)
      puts "Checking for 5.8.0.0 - #{eqstatus}"
       if(eqstatus)
          value = 4 # 5.8.0.0
      end
      return value
end

def get_ruby_path()
  if RUBY_PLATFORM =~ /(win|w)32$/
    File.join($startdir,'res/build-tools/RhoRuby.exe')
  else
    File.join($startdir,'res/build-tools/RubyMac')
  end
end

module WM
  def self.config
    unless $sdk
      #$sdk = "Windows Mobile 6 Professional SDK (ARMV4I)"
      #$sdk = $app_config["wm"]["sdk"] if $app_config["wm"] && $app_config["wm"]["sdk"]
      #value = ENV['rho_wm_sdk']
      #$sdk = value if value
      $sdk = "MC3000c50b (ARMV4I)"
    end

    $rubypath = get_ruby_path #"res/build-tools/RhoRuby.exe" #path to RubyMac
    $builddir = $config["build"]["wmpath"] + "/build"
    $vcbindir = $config["build"]["wmpath"] + "/bin"
    $appname = $app_config["name"].nil? ? "Rhodes" : $app_config["name"]
    $bindir = $app_path + "/bin"
    $rhobundledir =  $app_path + "/RhoBundle"
    $log_file = $app_config["applog"].nil? ? "applog.txt" : $app_config["applog"]
    $srcdir =  $bindir + "/RhoBundle"
    $buildcfg = $app_config["buildcfg"] unless $buildcfg
    $buildcfg = "Release" unless $buildcfg
    $detoolappflag = $js_application == true ? "js" : "ruby"
    $tmp_dir = File.join($bindir, "tmp")

    if $sdk == "Windows Mobile 6 Professional SDK (ARMV4I)"
        $targetdir = $bindir + "/target/wm6p"
    else
        $targetdir = $bindir + "/target/#{$sdk}"
    end

    $tmpdir =  $bindir +"/tmp"
    $vcbuild = $config["env"]["paths"]["vcbuild"]
    $vcbuild = "vcbuild" if $vcbuild.nil?
    $nsis    = $config["env"]["paths"]["nsis"]
    $nsis    = "makensis.exe" if $nsis.nil?
    $cabwiz = File.join($config["env"]["paths"]["cabwiz"], "cabwiz.exe") if $config["env"]["paths"]["cabwiz"]
    $cabwiz = "cabwiz" if $cabwiz.nil?
    $webkit_capability = !($app_config["capabilities"].nil? or $app_config["capabilities"].index("webkit_browser").nil?)
    $webkit_out_of_process = $app_config['wm']['webkit_outprocess'] == '1'
    $symbol_capability = !($app_config["capabilities"].nil? or $app_config["capabilities"].index("symbol").nil?)
    $additional_dlls_path = nil
    $additional_regkeys = nil
    $use_direct_deploy = "yes"
    $build_persistent_cab = Jake.getBuildBoolProp("persistent")
    $run_on_startup = Jake.getBuildBoolProp("startAtBoot")
    $build_cab = true
    $is_webkit_engine = false
    #$is_webkit_engine = true if !$app_config["wm"]["extensions"]["webkit"].nil? 
    #$app_config["wm"]["webengine"] == "webkit" if !$app_config["wm"]["webengine"].nil?
    #$is_webkit_engine = false if $is_webkit_engine.nil?

    if $wk_data_dir.nil?
      $wk_data_dir = File.join($startdir, "libs/data") #"/Program Files" # its fake value for running without symbol extensions. do not delete
      begin
        if $webkit_capability || $symbol_capability
          require "rhoelements-data"
          $wk_data_dir = File.join($startdir, "libs/data")
        end
      rescue Exception => e
        #puts "rhoelements gem is't found, webkit capability is disabled"
        #$webkit_capability = false
        #$symbol_capability = false
      end
    end

    unless $build_solution
      $build_solution = ($js_application and $app_config["capabilities"].index('shared_runtime')) ? 'rhodes_js.sln' : 'rhodes.sln'
    end

    if $app_config["wm"].nil?
      $port = "11000"
    else
      $port = $app_config["wm"]["logport"].nil? ? "11000" : $app_config["wm"]["logport"]
    end

    $excludelib = ['**/builtinME.rb','**/ServeME.rb','**/dateME.rb','**/rationalME.rb']

    $wm_emulator = $app_config["wm"]["emulator"] if $app_config["wm"] and $app_config["wm"]["emulator"]
    $wm_emulator = "Windows Mobile 6 Professional Emulator" unless $wm_emulator

    puts "$sdk [#{$sdk}]"
  end

  def self.edit_rhodes_rc
    rhodes_dir = File.join(File.dirname(__FILE__), '../../..')

    version = File.read(File.join(rhodes_dir, 'version')).chomp

    ar_ver = []
    version.split('.').each do |token|
      digits = /[0-9]+/.match(token)
      digits = '0' unless digits
      ar_ver << digits
    end
    ar_ver << '0' while ar_ver.length < 5

    Jake.edit_lines(File.join(rhodes_dir, 'platform/wm/rhodes/Rhodes.rc')) do |line|
      case line

      # FILEVERSION 2,0,0,5
      # PRODUCTVERSION 2,0,0,5
      when /^(\s*(?:FILEVERSION|PRODUCTVERSION)\s+)\d+,\d+,\d+,\d+\s*$/
        "#{$1}#{ar_ver[0, 4].join(',')}"

      # VALUE "FileVersion", "2, 0, 0, 5"
      # VALUE "ProductVersion", "2, 0, 0, 5"
      when /^(\s*VALUE\s+"(?:FileVersion|ProductVersion)",\s*)"\d+,\s*\d+,\s*\d+,\s*\d+"\s*$/
        "#{$1}\"#{ar_ver[0, 4].join(', ')}\""

      # VALUE "InternalName", "RhoElements"
      # VALUE "ProductName", "RhoElements"
      when /^(\s*VALUE\s+"(?:InternalName|ProductName)",\s*)".*"\s*$/
        "#{$1}\"#{$appname}\""

      # VALUE "FileDescription", "RhoElements Application"
      when /^(\s*VALUE\s+"FileDescription",\s*)".*"\s*$/
        "#{$1}\"#{$appname} application\""

      # VALUE "OriginalFilename", "RhoElements.exe"
      when /^(\s*VALUE\s+"OriginalFilename",\s*)".*"\s*$/
        "#{$1}\"#{$appname}.exe\""

      # VALUE "LegalCopyright", "Symbol Technologies, Inc., Copyright (C) 2012"
      when /^(\s*VALUE\s+"LegalCopyright",\s*)".*"\s*$/
        if $app_config['copyright'].nil?
          line
        else
          "#{$1}\"#{$app_config['copyright']}\""
        end

      else
        line
      end
    end
  end
end

def get_7z_path()
  if RUBY_PLATFORM =~ /(win|w)32$/
    File.join($startdir,'res/build-tools/7za')
  else
    '7za'
  end
end

def pack_7z(where, what, archive, exclude = [])
  what = what.map {|p| "\"#{p}\""}
  Jake.run3(get_7z_path() + " a \"#{archive}\" #{what.join(' ')} -bd" + (exclude.map {|f| " -x!#{f}"}).join(' '), where)
end

def unpack_7z(where, archive)
  Jake.run3(get_7z_path()+" x \"#{archive}\" -bd -y", where)
end

def unpack_7z_path(where, archive, path_inside_archive)
  Jake.run3(get_7z_path()+" x \"#{archive}\" \"#{path_inside_archive}\" -bd -y", where)
end

def determine_prebuild_path_win(platform,config)
  RhoPackages.request 'rhodes-containers'
  require 'rhodes/containers'
  if platform == 'win32' && !config.nil? && config.is_a?(Hash) && config.has_key?("app_type")
    conf = config.clone
    conf.delete("app_type")
  else
    conf = config
  end
  Rhodes::Containers::get_container_path_prefix(platform, conf)
end

def get_yaml_section(yaml_map, keys_array)
  section = yaml_map
  
  keys_array.each { |key|
    return nil if section[key.to_s].nil?
    
    section = section[key.to_s]
  }
  
  section 
end

def additional_dlls_paths_common(files_path_keys)
  $additional_dlls_paths_tmp = [] 

  $app_extensions_list.each do |ext, commin_ext_path|
    next unless commin_ext_path

    ext_config_path = File.join(commin_ext_path, 'ext.yml')

    next unless File.exist?(ext_config_path)

    ext_config = Jake.config(File.open(ext_config_path))

    files_path = get_yaml_section(ext_config, files_path_keys)    

    next unless files_path

    is_prebuilt     = ext_config[$current_platform] && ext_config[$current_platform]['exttype'] && ext_config[$current_platform]['exttype'] == 'prebuilt'
    is_project_path = ext_config['project_paths'] && ext_config['project_paths'][$current_platform] != nil

    next unless File.exists?(File.join(commin_ext_path, 'ext', 'build.bat')) || is_prebuilt || is_project_path

    $additional_dlls_paths_tmp << File.expand_path(files_path, commin_ext_path)
  end

  $additional_dlls_paths_tmp
end

def additional_dlls_paths
  unless defined?($additional_dlls_paths_)

    $additional_dlls_paths_ = []
        
    common_files = ["wm", "files", "common"]
         
    $additional_dlls_paths_ = additional_dlls_paths_common(common_files)  
  end
  
  $additional_dlls_paths_
end

def additional_dlls_persistent_paths  
  unless defined?($additional_dlls_paths_)
 
    $additional_dlls_paths_ = []
    
    common_files     = ["wm", "files", "common"]
    $additional_dlls_paths_ = additional_dlls_paths_common(common_files)
    
    persistent_files = ["wm", "files", "persistent"]
    persistent_dlls_paths_ = additional_dlls_paths_common(persistent_files)
       
    $additional_dlls_paths_.concat(persistent_dlls_paths_)
  end
  
  $additional_dlls_paths_
end

def kill_detool
  begin 
    `taskkill /F /IM detool.exe`
  rescue Exception => e
  end  
end

def sign(cabfile, signature)
  print_timestamp('signing CAB file START')
  puts "Singing .cab file"

  cabsigntool = $cabwiz[0, $cabwiz.index("CabWiz")] + "Security\\CabSignTool\\cabsigntool" if $config["env"]["paths"]["cabwiz"]
  cabsigntool = "cabsigntool" if cabsigntool.nil?

  cab_in  = cabfile
  cab_out = cabfile

  #TODO: need better solution, maybe just let know users on wiki to add bin dir of MS SDKs to PATH variable
  #Assuming that MS SDKs intalled to default path on c: or d: disk
  if Dir.exists?("C:\\Program Files\\Microsoft SDKs\\Windows\\v6.0A\\bin")
    ENV['PATH'] = ENV['PATH'] + "C:\\Program Files\\Microsoft SDKs\\Windows\\v6.0A\\bin" + ";"
  end
  
  if Dir.exists?("D:\\Program Files\\Microsoft SDKs\\Windows\\v6.0A\\bin")
    ENV['PATH'] = ENV['PATH'] + "D:\\Program Files\\Microsoft SDKs\\Windows\\v6.0A\\bin" + ";"
  end

  if system(cabsigntool + " "  + cab_in + " " + cab_out + " -F " + signature)
    puts "\nSigned successfully.\n\n"
  else
    puts "\nFailed to sign .cab file!\n\n"
  end
  print_timestamp('signing CAB file FINISH')
  $stdout.flush
end

# make a *.cpy and *.reg files for persistent installation
def makePersistentFiles(dstDir, additional_paths, webkit_dir, webkit_out_of_process, regkeys_filename)
  cf = File.new(File.join(dstDir, $appname + ".cpy"), "w+")

  if cf.nil?
    puts "errir file"
  end

  currDir = Dir.pwd
  chdir dstDir

  Dir.glob("**/*").each { |f|
    if File.directory?(f) == false
      path = "\\application\\"   + $appname + "\\rho\\" + f.to_s + " > " + "\\program files\\" + $appname + "\\rho\\" + f.to_s
      path.gsub!("/", "\\")
      cf.puts(path)
    end
  }

  if additional_paths.kind_of?(Array)
    additional_paths.each { |dir|
      chdir dir

      if File.exist? "files.yml"
        files_config = YAML::load(File.open("files.yml"))
        #files_config = Jake.config(File.open("files.yml"))

        continue unless files_config["files"] || files_config["files"]["persistent"]

        files_config["files"]["persistent"].each { |path|
          path.gsub!("/", "\\")
          cf.puts(path)
        }
      else       
        Dir.glob("**/*").each { |f|
          if File.directory?(f) == false
            path = "\\application\\"   + $appname + "\\" + f.to_s + " > " + "\\program files\\" + $appname + "\\" + f.to_s
            path.gsub!("/", "\\")
            cf.puts(path)
          end
        }
      end
    }
  end

  if !webkit_dir.nil?
    chdir webkit_dir

    Dir.glob("**/*").each { |f|
      if File.directory?(f) == false && File.extname(f) != ".lib" && File.extname(f) != ".exp"
        next if File.basename(f) == (webkit_out_of_process ? 'WebkitPlatformDeliveryCompiledAsDLL.dll' : 'OutProcessWK.exe')
        path = "\\application\\"   + $appname + "\\" + f.to_s + " > " + "\\program files\\" + $appname + "\\" + f.to_s
        path.gsub!("/", "\\")
        cf.puts(path)
      end
    }
  end

  build_dir = File.join($startdir, "platform", 'wm', "bin", $sdk, "Rhodes", $buildcfg)
  chdir build_dir

  Dir.glob("**/*").each { |f|
    if File.directory?(f) == false && (File.extname(f) == ".exe" || File.extname(f) == ".dll") && f != "rhodes.exe"
      path = "\\application\\"   + $appname + "\\" + f.to_s + " > " + "\\program files\\" + $appname + "\\" + f.to_s
      path.gsub!("/", "\\")
      cf.puts(path)
    end
  }

  cf.close

  rf = File.new(File.join(dstDir, $appname + ".reg"), "w+")

  if File.exist?(regkeys_filename)
    File.readlines(regkeys_filename).each do |line|
      parts = line.split(",")

      if parts.length < 5
        next
      end

      # 0    1                        2       3          4
      # HKLM,Software\Company\AppName,another,0x00000000,alpha

      value_name = ""
      key_name   = "["

      case parts[0]
      when "HKLM"
        key_name += "HKEY_LOCAL_MACHINE\\"
      when "HKCU"
        key_name += "HKEY_CURRENT_USER\\"
      when "HKCR"
        key_name += "HKEY_CLASSES_ROOT\\"
      end

      key_name += parts[1]
      key_name += "]"

      rf.puts key_name

      if parts[2].nil? || parts[2] == ""
        value_name = "@="
      else
        value_name = "\"" + parts[2] + "\"="
      end

      val = parts[4].gsub(/[^0-9A-Za-z.\\\/\-{} *]/, '')

      if parts[3] == "0x00010001"
        value_name += "dword:"
        value_name += val
      else
        value_name += "\"" + val + "\""
      end

      rf.puts value_name
      rf.puts
    end
  end

  rf.close

  chdir currDir
end

def build_rholaunch
  chdir File.join( $config["build"]["wmpath"], "RhoLaunch")

  cp $app_path + "/icon/icon.ico", "./RhoLaunch.ico" if File.exists? $app_path + "/icon/icon.ico"

  args = ['/M4', "RhoLaunch.sln", "\"Release|#{$sdk}\""]
  puts "\nThe following step may take several minutes or more to complete depending on your processor speed\n\n"
  puts Jake.run($vcbuild,args)
  unless $? == 0
    puts "Error building"
    exit 1
  end
  chdir $startdir

end

def stuff_around_appname
  if !$use_shared_runtime
    out_dir = File.join($startdir, $vcbindir, $sdk, 'rhodes', 'Release')
    cp File.join(out_dir, 'rhodes.exe'), File.join(out_dir, "#{$appname}.exe")
  end

  wm_icon = $app_path + '/icon/icon.ico'
  if $use_shared_runtime
    if $js_application
      shortcut_content = '"\\Program Files\\RhoElements\\RhoElements.exe" -jsapproot="\\Program Files\\' + $appname + '"'
    else
      shortcut_content = '"\\Program Files\\RhoElements\\RhoElements.exe" -approot="\\Program Files\\' + $appname + '"'
    end

    if File.exists? wm_icon then
      shortcut_content = shortcut_content + '?"\\Program Files\\' + $appname + '\\rho\\icon\\icon.ico"'
    end
    shortcut_content = shortcut_content.length().to_s + '#' + shortcut_content
    File.open($srcdir + '/../' + $appname + ".lnk", "w") { |f| f.write(shortcut_content) }
  end

  if $run_on_startup
    shortcut_content = '"\\Program Files\\' + $appname + "\\" + $appname + '.exe" -minimized=""'
    if File.exists? wm_icon then
      shortcut_content = shortcut_content + '?"\\Program Files\\' + $appname + '\\rho\\icon\\icon.ico"'
    end
    shortcut_content = shortcut_content.length().to_s + '#' + shortcut_content
    File.open(File.join($srcdir, 'apps', $appname + "Min.lnk"), "w") { |f| f.write(shortcut_content) } 
  end
end

def build_cab
  print_timestamp('build CAB file START')
  build_platform = 'ce5' #if $sdk == "MC3000c50b (ARMV4I)"

  reg_keys_filename = File.join(File.dirname(__FILE__), 'regs.txt');
  com_dlls_filename = File.join(File.dirname(__FILE__), 'comdlls.txt');
  
  puts 'remove file with registry keys'
  rm reg_keys_filename if File.exists? reg_keys_filename

  if $regkeys && $regkeys.size > 0
    puts 'add registry keys to file'
    File.open(reg_keys_filename, 'w') do |f|
      $regkeys.each { |key| f.puts(key + "\n") }
    end
  end

  if $comdll_files #&& $comdll_files.size > 0
    puts 'add com dlls names to file'
    reg_string = ""
     
    File.open(com_dlls_filename, 'w') do |f|
    #  $comdll_files.each { |key| 
    #    reg_string = reg_string + key[0..-1] + "," 
    #  }

    #  reg_string = reg_string[0..-2]
    #  f.write(reg_string)
    f.write("rhobrowser.dll")
    end
  end
  
  if $build_persistent_cab && !$use_shared_runtime
    #TODO TAU
    #makePersistentFiles($srcdir, additional_dlls_persistent_paths, $webkit_capability ? $wk_data_dir : nil, $webkit_out_of_process, reg_keys_filename)
    makePersistentFiles($srcdir, additional_dlls_persistent_paths, nil, $webkit_out_of_process, reg_keys_filename)
  end

=begin
  webkit = 'none'
  if $is_webkit_engine && $webkit_capability 
    webkit = $webkit_out_of_process ? 'out_of_process' : 'in_process'
  end
=end

  #TODO TAU
  webkit = 'none'
  
  if $is_webkit_engine #&& $webkit_capability 
    webkit = 'in_process'
  end
  
  $wk_data_dir = File.join($startdir, "../rho-tau-extensions-"+ENV['rhodes_version'])

  dir = File.join($startdir, $builddir)
  
  args = [
    'build_inf.js',
    '"' + $appname + ".inf\"",               #0
    build_platform,                           #1
    '"' + $app_config["name"] +'"',           #2
    '"' + $app_config["vendor"] + '"',        #3
    '"' + $srcdir + '"',                      #4
    $hidden_app,                              #5
    webkit,                                   #6
    '"' + $wk_data_dir + '"',                 #7
    ($use_shared_runtime  ? "1" : "0"),       #8
    ($symbol_capability ? "1" : "0"),       #9
    ($run_on_startup      ? "1" : "0"),       #10
    '"' + $srcdir + '"',                      #11
    ($build_persistent_cab ? "1" : "0")       #12
  ]

  if $build_persistent_cab
    args.concat(additional_dlls_persistent_paths)
  elsif !$use_shared_runtime
    args.concat(additional_dlls_paths)
  end
  
  Jake.run3("cscript #{args.join(' ')}", dir)

  Jake.run3("\"#{$cabwiz}\" \"#{$appname}.inf\"", dir)
  Jake.run3('cscript cleanup.js', dir)

  mkdir_p $targetdir
  rm File.join(dir, "comdlls.txt") if File.exist? File.join(dir, "comdlls.txt")
  rm File.join(dir, "regs.txt") if File.exist? File.join(dir, "regs.txt")
  mv File.join(dir, "#{$appname}.inf"), $targetdir
  mv File.join(dir, "#{$appname}.cab"), $targetdir

  File.open(File.join($targetdir, 'app_info.txt'), 'w') { |f| f.write("#{$app_config['vendor']} #{$appname}/#{$appname}.exe") }

  if not $config['build']['wmsign'].nil? and $config['build']['wmsign'] != ''
    sign("\"#{$targetdir}/#{$appname}.cab\"", $config['build']['wmsign'])
  end

  rm File.join(dir, 'cleanup.js')
  print_timestamp('build CAB file FINISH')
end

def clean_ext_vsprops(ext_path)
  Dir.glob(File.join(ext_path, '**', '*.vsprops')) do |file|
    Jake.clean_vsprops(file)
  end
end

def ext_add_reg_key(ext, key)
  puts "extension " + ext + " add regkey to cab. key: " + key
  $regkeys << key
end

def ext_add_reg_com_dll(ext, dll_name)
  puts "extension " + ext + " add COM dll to registration. dll: " + dll_name
  $comdll_files << dll_name
end

namespace "config" do
  task :set_wince_platform do
    $current_platform = "wm" unless $current_platform
    $sdk = "MC3000c50b (ARMV4I)"
  end

  task :set_wm_platform do
    $current_platform = "wm" unless $current_platform
      if($current_platform=='wm')
        #$webkiLibraryCheck = File.join($startdir,'/thirdpartyWebkit.zip')
        #if !File.exists? ($webkiLibraryCheck)
        #  puts "\nWindows Mobile or Windows CE applications require additional components for built. Please refer the documentation available at the below link.\nhttps://github.com/rhomobile/rhodes/blob/master/doc/oss/DeveloperNotes.md#third-party-webkit-dependencies-for-wmce\n"
        #  exit 1
        #end
      end
  end

  task :set_win32_platform do
    $current_platform = "win32" unless $current_platform
    $sdk = "win32"
  end

  task :wm => [:set_wm_platform, "config:common"] do
    puts " $current_platform : #{$current_platform}"

    WM.config
  end

  namespace :wm do
    task :set_wk_data_dir, :wk_data_dir do |t, args|
      $wk_data_dir = args[:wk_data_dir]
    end
    namespace :win32 do
      task :ignore_vsprops do
        $wm_win32_ignore_vsprops = true
      end
    end
  end

  namespace "win32" do
    namespace :wm do
      task :ignore_vsprops do
        $wm_win32_ignore_vsprops = true
      end
    end

    task :qt do
      next if $prebuild_win32

      $msvc_version = $app_config["win32"]["msvc"] if $app_config && $app_config["win32"] && $app_config["win32"]["msvc"]

      # use Visual Studio 2015 by default
      $vs_version = 2015
      $vscommontools = ENV['VS140COMNTOOLS']
      $qmake_makespec = 'win32-msvc2015'
      
      # if win32:msvc is not defined in build.yml, then automatically detect installed Visual Studio
      if $msvc_version.nil?
        unless !$vscommontools.nil? && ($vscommontools !~ /^\s*$/) && File.directory?($vscommontools)
          $vs_version = 2008
          $vscommontools = ENV['VS90COMNTOOLS']
          $qmake_makespec = 'win32-msvc2008'
        end
        unless !$vscommontools.nil? && ($vscommontools !~ /^\s*$/) && File.directory?($vscommontools)
          $vs_version = 2012
          $vscommontools = ENV['VS110COMNTOOLS']
          $qmake_makespec = 'win32-msvc2012'
          
        end
        unless !$vscommontools.nil? && ($vscommontools !~ /^\s*$/) && File.directory?($vscommontools)
          puts "\nPlease, set either VS110COMNTOOLS or VS90COMNTOOLS environment variable to Common7\\Tools directory path of Visual Studio 2012 or 2008 respectively."
          exit 1
        end
      elsif $msvc_version == "2008"
        $vs_version = 2008
        $vscommontools = ENV['VS90COMNTOOLS']
        $qmake_makespec = 'win32-msvc2008'
        unless !$vscommontools.nil? && ($vscommontools !~ /^\s*$/) && File.directory?($vscommontools)
          puts "\nPlease, set VS90COMNTOOLS environment variable to Common7\\Tools directory path of Visual Studio 2008"
          exit 1
        end
      elsif $msvc_version == "2012"
        $vs_version = 2012
        $vscommontools = ENV['VS110COMNTOOLS']
        $qmake_makespec = 'win32-msvc2012'
        unless !$vscommontools.nil? && ($vscommontools !~ /^\s*$/) && File.directory?($vscommontools)
          puts "\nPlease, set VS110COMNTOOLS environment variable to Common7\\Tools directory path of Visual Studio 2012"
          exit 1
        end
      elsif $msvc_version == "2015"
        $vs_version = 2015
        $vscommontools = ENV['VS140COMNTOOLS']
        $qmake_makespec = 'win32-msvc2015'
        
        unless !$vscommontools.nil? && ($vscommontools !~ /^\s*$/) && File.directory?($vscommontools)
          puts "\nPlease, set VS110COMNTOOLS environment variable to Common7\\Tools directory path of Visual Studio 2015"
          exit 1
        end
      else
        puts "\nPlease, specify Visual Studio version as either 2008 or 2012 or 2015 in win32:msvc section of build.yml"
        exit 1
      end

      if $vscommontools.frozen?
        $vscommontools = $vscommontools.dup
      end

      $vscommontools << '\\' unless $vscommontools.end_with?('\\') || $vscommontools.end_with?('/')

      $qtdir = ENV['QTDIR']
      unless !$qtdir.nil? && ($qtdir !~ /^\s*$/) && File.directory?($qtdir)
        puts "\nPlease, set QTDIR environment variable to Qt root directory path"
        exit 1
      end

     # Search for QT 5 or QT 4 files
     qt5corefile =File.join($qtdir, "bin/Qt5Core.dll");
     qt4corefile =File.join($qtdir, "bin/QtCore4.dll");
     if File.exists?(qt5corefile)
          qtcorefile=qt5corefile
     elsif  File.exists?(qt4corefile)
          qtcorefile=qt4corefile
     end
     
     if qtcorefile.nil?
          puts "\nNo QT File exists in #{$qtdir}"
          exit 1
     end
     
          $QVersion=GetFileVersion(qtcorefile)
          puts "Current QT Version Found : #{$QVersion}"
          $qtversionindex = QTInfo($QVersion)
          puts "QT Version Found and Index for further checking is #{$qtversionindex}"
          
          case $qtversionindex
               when 1
                    format= "Found QT Version : #{$QVersion}"
               when 2     
                    format ="Found QT Version : #{$QVersion}"
               when 3
                    format ="Found QT Version : #{$QVersion}"
               when 4
                    format ="Found QT Version : #{$QVersion}"
               else
                    format ="Unknown QT Version : #{$QVersion}"
          end
          puts format
          puts "Visual Studio Found/Default for build.yml is #{$vs_version} , Code will be Compiled against Visual Studio #{$vs_version}"
          
         if $vs_version == 2008 &&  $qtversionindex == 3
               puts "\n Visual Studio 2008 is not currently supported for this QT version "
          exit 1
        end
          if $vs_version != 2015 &&  $qtversionindex == 4
               puts "\n Visual Studio  #{$vs_version} is not currently supported for this QT version "
          exit 1
        end
       
      $qt_project_dir = File.join( $startdir, 'platform/shared/qt/' )
    end

    task :application do
      $app_version = '1.0'
      $app_version = $app_config["version"] unless $app_config["version"].nil?
      
      require $startdir + "/lib/rhodes.rb"
      fversion = StringIO.new("", "w+")          
      fversion.write( "#define RHOSIMULATOR_NAME \"RhoSimulator\"\n" )
      fversion.write( "#define RHOSIMULATOR_VERSION \"#{Rhodes::VERSION}\"\n" )
      fversion.write( "#define APPLICATION_NAME \"#{$appname}\"\n" )
      fversion.write( "#define APPLICATION_VERSION \"#{$app_version}\"\n" )
      Jake.modify_file_if_content_changed( File.join($startdir, 'platform/shared/qt/rhodes/RhoSimulatorVersion.h'), fversion )  

      $app_icon_path = $app_path + "/icon/icon.ico"
      $app_icon_path = $startdir + "/res/icons/rhodes.ico" unless File.exists? $app_icon_path
      cp $app_icon_path, $startdir + "/platform/shared/qt/rhodes/resources/rho.ico"

      $qt_icon_path = $app_path + "/icon/icon.png"
      $qt_icon_path = $startdir + "/res/icons/rhodes.png" unless File.exists? $qt_icon_path
      cp $qt_icon_path, $startdir + "/platform/shared/qt/rhodes/resources/rho.png"
      qrcfile = $startdir + "/platform/shared/qt/rhodes/GeneratedFiles/" + $buildcfg + "/qrc_simulator.cpp"
      rm qrcfile if File.exists? qrcfile
    end

  end
end

namespace "build" do

  namespace "windows" do
    task :devrhobundle, [:sdk, :configuration] do |t,args|
      throw "You must pass in sdk(Win32, WM, WinCE)" if args.sdk.nil?
      throw "You must pass in configuration(Debug, Release)" if args.configuration.nil?

      if ( args.sdk == 'Win32' ) 
        $current_platform = "win32"
        $sdk = "Win32"
      elsif ( args.sdk == 'WM' )
        $current_platform = "wm"
      elsif ( args.sdk == 'WinCE' ) 
        $current_platform = "wm"
        $sdk = "MC3000c50b (ARMV4I)"
      else
        throw "You must pass in sdk(Win32, WM, WinCE)"
      end

      $buildcfg = args.configuration

      Rake::Task["config:qt"].invoke() if $current_platform == "win32"
      Rake::Task["config:win32:qt"].invoke() if $current_platform == "win32"  
      Rake::Task["build:wm:rhobundle"].invoke  
      Rake::Task["config:win32:application"].invoke() if $current_platform == "win32"
      Rake::Task["build:win32:after_bundle"].invoke  
    end
  end

  namespace "wm" do
  
    task :extensions => "config:wm" do
      print_timestamp('build:wm:extensions START')
      next if $use_shared_runtime || $prebuild_win32

      extensions_lib = ''
      pre_targetdeps = ''

      $regkeys      = Array.new
      $comdll_files = Array.new
      
      puts "$app_extensions_list : #{$app_extensions_list}"
      
      $app_extensions_list.each do |ext, commin_ext_path |
          next unless commin_ext_path
          print_timestamp('process extension "'+ext+'" START')
          
          extpath = File.join( commin_ext_path, 'ext')
          ext_config_path = File.join( commin_ext_path, "ext.yml")
          ext_config = nil
          
          #puts "ext_config_path - " + ext_config_path.to_s
          if File.exist? ext_config_path
            ext_config = Jake.config(File.open(ext_config_path))
          end
          nlib = ext_config['nativelibs'] if ext_config
          nlib = [] unless nlib

          puts "#{ext_config}"
          is_prebuilt = ext_config && ext_config[$current_platform] && ext_config[$current_platform]['exttype'] && ext_config[$current_platform]['exttype'] == 'prebuilt'
          project_path = ext_config["project_paths"][$current_platform] if ( ext_config && ext_config["project_paths"] && ext_config["project_paths"][$current_platform])
          target_lib_name = Jake.getBuildProp('target_lib_name', ext_config) if ext_config
          
          next unless (File.exists?( File.join(extpath, "build.bat") ) || is_prebuilt || project_path)


          chdir commin_ext_path 
            
          puts 'start read reg key'
          if !(ext_config.nil?)
            if !(ext_config["regkeys"].nil?)
              ext_config["regkeys"].each do |key|
                if key.kind_of?(String)
                  ext_add_reg_key(ext, key)
                end
              end
            end
            
            if $app_config["wm"] && ($app_config["wm"]["regkeys"] != nil) && $app_config["wm"]["regkeys"].kind_of?(Array)
              $app_config["wm"]["regkeys"].each do |keygroup|
                if (ext_config["regkeys_#{keygroup}"] != nil)
                  ext_config["regkeys_#{keygroup}"].each do |key|
                    ext_add_reg_key(ext, key)
                  end
                end
              end
            end
          end
          puts 'end read reg key'
 
          if (ext_config["wm"] != nil && ext_config["wm"]["register"] != nil)
            ext_config["wm"]["register"].each do |key|
              ext_add_reg_com_dll(ext, key)
            end
          end        
          
          if ext != 'openssl.so'
            if ext_config.has_key?('libraries')
              ext_config["libraries"].each { |name_lib|
                extensions_lib << " #{name_lib}.lib"
                pre_targetdeps << " ../../../win32/bin/extensions/#{name_lib}.lib"
              }
            else
              extensions_lib << " #{ext}.lib"
              pre_targetdeps << " ../../../win32/bin/extensions/#{ext}.lib"
            end
          end

          if (project_path)
          
              ENV['RHO_PLATFORM'] = $current_platform
              ENV['RHO_ROOT'] = $startdir
              ENV['SDK'] = $sdk
              ENV['RHO_BUILD_CONFIG'] = $buildcfg
              ENV['VCBUILD'] = $vcbuild
              ENV['RHO_PROJECT_PATH'] = File.join(commin_ext_path, project_path)

              if $current_platform == 'win32'
                ENV['TARGET_TEMP_DIR'] = File.join(ENV['PWD'], "platform", "win32", "bin", "extensions")
                ENV['TEMP_FILES_DIR'] = File.join(ENV['TARGET_TEMP_DIR'], ext)
              else
                ENV['TARGET_TEMP_DIR'] = File.join($startdir, "platform", 'wm', "bin", $sdk, "rhodes", $buildcfg)
                ENV['TEMP_FILES_DIR'] = File.join($startdir, "platform", 'wm', "bin", $sdk, "extensions", ext)
              end

              ENV['RHO_EXT_NAME']=ext
              ENV['RHO_EXT_LIB_NAME'] = target_lib_name
              #ENV["TARGET_EXT_DIR"] = File.join $startdir,'bin','target','wm','release','extensions'
              
              if is_prebuilt
                  file_mask = File.join(extpath, $current_platform + ($current_platform=='wm' ? '/lib' : '' ) + '/*.lib' ) 
 
                  puts "PREBUILD: #{file_mask}"
                
                  mkdir_p ENV['TARGET_TEMP_DIR'] unless File.exist? ENV['TARGET_TEMP_DIR']
                  Dir.glob( file_mask ).each do |lib|
                      cp_r lib, ENV['TARGET_TEMP_DIR']
                  end
              else    
                  clean_ext_vsprops(commin_ext_path) if $wm_win32_ignore_vsprops
                  Jake.run3('rake --trace', File.join($startdir, 'lib/build/extensions'))

                  if ENV["TARGET_EXT_DIR"]
                    nlib.each do |lib|
                      lib_file = File.join(commin_ext_path, lib)

                      cp(lib_file, File.join(ENV['TARGET_EXT_DIR'], ext)) if File.exists? lib_file
                    end
                  end
              end    
          
          else
              chdir $startdir
          
              ENV['RHO_PLATFORM'] = $current_platform
              ENV['RHO_BUILD_CONFIG'] = 'Release'
              ENV['PWD'] = $startdir
              ENV['RHO_ROOT'] = ENV['PWD']

              if ENV["TARGET_EXT_DIR"]
                ENV['TARGET_TEMP_DIR'] = File.join(ENV["TARGET_EXT_DIR"], ext)
              else
                ENV['TARGET_TEMP_DIR'] = File.join(ENV['PWD'], "platform", 'wm', "bin", $sdk, "rhodes", $current_platform == 'wm' ? "Release" : $buildcfg)
              end
              ENV['RHO_EXT_NAME']=ext                

              ENV['TEMP_FILES_DIR'] = File.join(ENV['PWD'], "platform",  'wm', "bin", $sdk, "extensions", ext)

              unless ENV["TARGET_EXT_DIR"]
                if $current_platform == 'win32'
                  ENV['TARGET_TEMP_DIR'] = File.join(ENV['PWD'], "platform", "win32", "bin", "extensions")
                  ENV['TEMP_FILES_DIR'] = File.join(ENV['TARGET_TEMP_DIR'], ext)
                end
              end

              ENV['VCBUILD'] = $vcbuild
              ENV['SDK'] = $sdk
              ENV['RHO_QMAKE'] = $qmake
              ENV['RHO_QMAKE_VARS'] = $rhosimulator_build ? 'RHOSIMULATOR_BUILD=1' : ''
              ENV['RHO_QMAKE_SPEC'] = $qmake_makespec
              ENV['RHO_VSCMNTOOLS'] = $vscommontools

              if File.exists? File.join(extpath, 'build.bat')
                clean_ext_vsprops(commin_ext_path) if $wm_win32_ignore_vsprops
                Jake.run3('build.bat', extpath)
              elsif is_prebuilt
                file_mask = File.join(extpath, $current_platform + ($current_platform=='wm' ? '/lib' : '' ) + '/*.lib' ) 
                puts "PREBUILD: #{file_mask}"
                
                mkdir_p ENV['TARGET_TEMP_DIR'] unless File.exist? ENV['TARGET_TEMP_DIR']
                Dir.glob( file_mask ).each do |lib|
                  cp_r lib, ENV['TARGET_TEMP_DIR']
                end
              end
          end
          
          chdir $startdir
          print_timestamp('process extension "'+ext+'" FINISH')
      end      
      generate_extensions_pri(extensions_lib, pre_targetdeps)
      print_timestamp('build:wm:extensions FINISH')
    end

    #    desc "Build wm rhobundle"
    task :rhobundle, [:exclude_dirs] do
      Rake::Task["config:wm"].invoke
      rm_rf $srcdir
      Rake::Task["build:bundle:noxruby"].invoke
      Rake::Task["build:wm:extensions"].execute if !$skip_build_extensions
      Jake.build_file_map( File.join($srcdir, "apps"), "rhofilelist.txt" )
    end

    task :rhodes => ["config:wm", "build:wm:rhobundle"] do
      print_timestamp('build:wm:rhodes START')
      if $use_shared_runtime then next end

      chdir $config["build"]["wmpath"]

      cp $app_path + "/icon/icon.ico", "rhodes/resources" if File.exists? $app_path + "/icon/icon.ico"

      WM.edit_rhodes_rc

      if $wm_win32_ignore_vsprops
        Dir.glob(File.join(File.dirname($build_solution), '*.vsprops')) do |file|
          Jake.clean_vsprops(file)
        end
      end

      args = ['/M4', $build_solution, "\"Release|#{$sdk}\""]
      puts "\nThe following step may take several minutes or more to complete depending on your processor speed\n\n"
      puts Jake.run($vcbuild,args)
      unless $? == 0
        puts "Error building"
        exit 1
      end
      chdir $startdir
      print_timestamp('build:wm:rhodes FINISH')
    end

    task :devrhobundle => ["config:set_wm_platform", "build:wm:rhobundle", "win32:after_bundle"]
    
    task :upgrade_package => ["config:wm"] do
      $skip_build_extensions = true
      
      Rake::Task["build:wm:rhobundle"].execute

      mkdir_p $targetdir if not File.exists? $targetdir
      zip_file_path = File.join($targetdir, "upgrade_bundle.zip")
      Jake.zip_upgrade_bundle( $bindir, zip_file_path)
    end
    
    # process partial update
    task :upgrade_package_partial => ["config:wm"] do    
        $skip_build_extensions = true
        
        Rake::Task["build:wm:rhobundle"].execute
        
        add_list_full_name = File.join($app_path, 'upgrade_package_add_files.txt')
        remove_list_full_name = File.join($app_path, 'upgrade_package_remove_files.txt')
      
        src_folder = File.join($bindir, 'RhoBundle')
        src_folder = File.join(src_folder, 'apps')
      
        tmp_folder = $bindir + '_tmp_partial'
        rm_rf tmp_folder if File.exists? tmp_folder
        mkdir_p tmp_folder

        dst_tmp_folder = File.join(tmp_folder, 'RhoBundle')
        mkdir_p dst_tmp_folder
        # copy all
        cp_r src_folder, dst_tmp_folder
        
        puts 'dst_tmp_folder=' + dst_tmp_folder.to_s
        
        dst_tmp_folder = File.join(dst_tmp_folder, 'apps')
        mkdir_p dst_tmp_folder

        add_files = []
        if File.exists? add_list_full_name
           File.open(add_list_full_name, "r") do |f|
              while line = f.gets
                 fixed_path = line.gsub('.rb', '.iseq').gsub('.erb', '_erb.iseq').chomp
                 add_files << fixed_path
                 puts '### ['+fixed_path+']'
              end
           end
        end
                
        remove_files = []
        if File.exists? remove_list_full_name
           File.open(remove_list_full_name, "r") do |f|
              while line = f.gets
                 fixed_path = line.gsub('.rb', '.iseq').gsub('.erb', '_erb.iseq').chomp
                 remove_files << fixed_path
                 #puts '### ['+fixed_path+']'
              end
           end
        end

        psize = dst_tmp_folder.size+1
        Dir.glob(File.join(dst_tmp_folder, '**/*')).sort.each do |f|
          relpath = f[psize..-1]

          if File.file?(f)
             #puts '$$$ ['+relpath+']'
             if (not add_files.include?(relpath)) && (relpath != 'rhofilelist.txt')
                 rm_rf f
             end 
          end
        end
              
        Jake.build_file_map( dst_tmp_folder, "upgrade_package_add_files.txt" )               

        if File.exists? remove_list_full_name
           File.open(File.join(dst_tmp_folder, 'upgrade_package_remove_files.txt'), "w") do |f|
              remove_files.each do |j|
                 f.puts "#{j}"
                 #f.puts "#{j}\tfile\t0\t0"
              end
           end
        end

        mkdir_p $targetdir if not File.exists? $targetdir
        zip_file_path = File.join($targetdir, "upgrade_bundle_partial.zip")
        Jake.zip_upgrade_bundle( tmp_folder, zip_file_path)
        rm_rf tmp_folder
    end    

  end #wm
  
  namespace "win32" do
    task :deployqt => "config:win32:qt" do

      FileUtils.rm_rf(Dir.glob(File.join($target_path, 'msvc*0.dll')), {:secure => true})
      FileUtils.rm_rf(Dir.glob(File.join($target_path, 'vcomp*0.dll')), {:secure => true})
      FileUtils.rm_rf(Dir.glob(File.join($target_path, 'vccorlib*0.dll')), {:secure => true})
      FileUtils.rm_rf(Dir.glob(File.join($target_path, 'D3Dcompiler*.dll')), {:secure => true})
      FileUtils.rm_rf(Dir.glob(File.join($target_path, 'Microsoft.VC*.manifest')), {:secure => true})
      deploymsvc = Jake.getBuildBoolProp('deploymsvc', $app_config, true)
      if(deploymsvc)
        puts "Microsoft Visual C++ Runtime Binaries for #{$vs_version} included in App Setup Bundle"
      else
        puts "Microsoft Visual C++ Runtime Binaries for #{$vs_version} Excluded in App Setup Bundle"
      end 
      if($rhosimulator_build)
        puts "Build for Rhosimulator...msvc"
        deploymsvc = true;
      end
      if ($vs_version == 2008)
        # Visual Studio 2008
        puts "Deploy libs from msvc #{$vs_version}"
        vsredistdir = File.join($vscommontools, "../../VC/redist/x86/Microsoft.VC90.CRT")
        vsredistdir2 = File.join($vscommontools, "../../VC/redist/x86/Microsoft.VC90.OPENMP")
        if deploymsvc
          cp File.join(vsredistdir, "msvcm90.dll"), $target_path
          cp File.join(vsredistdir, "msvcp90.dll"), $target_path
          cp File.join(vsredistdir, "msvcr90.dll"), $target_path
          cp File.join(vsredistdir, "Microsoft.VC90.CRT.manifest"), $target_path
          cp File.join(vsredistdir2, "vcomp90.dll"), $target_path
          cp File.join(vsredistdir2, "Microsoft.VC90.OpenMP.manifest"), $target_path
        end
        cp File.join($startdir, "lib/extensions/openssl.so/ext/win32/msvc2008/bin/libeay32.dll"), $target_path
        cp File.join($startdir, "lib/extensions/openssl.so/ext/win32/msvc2008/bin/ssleay32.dll"), $target_path
      elsif ($vs_version == 2012)
        # Visual Studio 2012
        puts "Deploy libs from msvc #{$vs_version}"
        vsredistdir = File.join($vscommontools, "../../VC/redist/x86/Microsoft.VC110.CRT")
        vsredistdir2 = File.join($vscommontools, "../../VC/redist/x86/Microsoft.VC110.OPENMP")
        if deploymsvc
          cp File.join(vsredistdir, "msvcp110.dll"), $target_path
          cp File.join(vsredistdir, "msvcr110.dll"), $target_path
          cp File.join(vsredistdir, "vccorlib110.dll"), $target_path
          cp File.join(vsredistdir2, "vcomp110.dll"), $target_path
          cp File.join($vscommontools, "../../VC/bin/D3Dcompiler_46.dll"), $target_path
          puts "Joining msvc110 libs"
        end
        cp File.join($startdir, "lib/extensions/openssl.so/ext/win32/bin/libeay32.dll"), $target_path
        cp File.join($startdir, "lib/extensions/openssl.so/ext/win32/bin/ssleay32.dll"), $target_path
      elsif ($vs_version == 2015)
        # Visual Studio 2015
        puts "Deploy libs from msvc #{$vs_version}"
        vsredistdir = File.join($vscommontools, "../../VC/redist/x86/Microsoft.VC140.CRT")
        vsredistdir2 = File.join($vscommontools, "../../VC/redist/x86/Microsoft.VC140.OPENMP")
        if deploymsvc
          cp File.join(vsredistdir, "msvcp140.dll"), $target_path
          cp File.join(vsredistdir, "concrt140.dll"), $target_path
          cp File.join(vsredistdir, "vccorlib140.dll"), $target_path
          cp File.join(vsredistdir, "vcruntime140.dll"), $target_path
          cp File.join(vsredistdir2, "vcomp140.dll"), $target_path
          cp File.join($vscommontools, "../../VC/bin/d3dcompiler_47.dll"), $target_path
        end
        cp File.join($startdir, "lib/extensions/openssl.so/ext/win32/bin/libeay32.dll"), $target_path
        cp File.join($startdir, "lib/extensions/openssl.so/ext/win32/bin/ssleay32.dll"), $target_path
      else
        puts "Libs version not correct"
      end

      FileUtils.rm_rf(File.join($target_path, 'phonon4.dll'), {:secure => true})
      FileUtils.rm_rf(File.join($target_path, 'libEGL.dll'), {:secure => true})
      FileUtils.rm_rf(File.join($target_path, 'libGLESv2.dll'), {:secure => true})
      FileUtils.rm_rf(Dir.glob(File.join($target_path, 'icu*5*.dll')), {:secure => true})
      FileUtils.rm_rf(Dir.glob(File.join($target_path, 'Qt*4.dll')), {:secure => true})
      FileUtils.rm_rf(Dir.glob(File.join($target_path, 'Qt5*.dll')), {:secure => true})
      target_if_path = File.join($target_path, 'imageformats/')
      FileUtils.rm_rf(target_if_path, {:secure => true})
      target_platforms_path = File.join($target_path, 'platforms/')
      FileUtils.rm_rf(target_platforms_path, {:secure => true})

      deployqt = Jake.getBuildBoolProp('deployqt', $app_config, true)
      if($rhosimulator_build)
            puts "Build for Rhosimulator...deployqt"
            deployqt = true;
      end
      if(deployqt)
          puts "QT  Binaries for #{$vs_version} included in App Setup Bundle"
      else
          puts "QT Binaries for #{$vs_version} Excluded in App Setup Bundle"      
      end    
      next unless deployqt

       #check the QT versions here for build purpose
       format = "Qt version now is #{$QVersion} and index is #{$qtversionindex}"
       puts format
     
     #1 - 4.7.4.0     
     #2- 5.1.1.0 
     #3 - 5.5.0.0
     #4 - 5.8.0.0
       case $qtversionindex
                 when 1 # 4.7.4.0
                    format ="Found QT Version : #{$QVersion}"
                    cp File.join($qtdir, "bin/phonon4.dll"), $target_path
                    cp File.join($qtdir, "bin/QtCore4.dll"), $target_path
                    cp File.join($qtdir, "bin/QtGui4.dll"), $target_path
                    cp File.join($qtdir, "bin/QtNetwork4.dll"), $target_path
                    cp File.join($qtdir, "bin/QtWebKit4.dll"), $target_path
                    if not File.directory?(target_if_path)
                    Dir.mkdir(target_if_path)
                    end
                    cp File.join($qtdir, "plugins/imageformats/qgif4.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qico4.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qjpeg4.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qmng4.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qsvg4.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qtiff4.dll"), target_if_path
                 when 2 # 5.1.1.0
                    format= "Found QT Version : #{$QVersion}"
                    if File.exists?(File.join($qtdir, "bin/icudt53.dll"))
                      cp File.join($qtdir, "bin/icudt53.dll"), $target_path
                      cp File.join($qtdir, "bin/icuuc53.dll"), $target_path
                      cp File.join($qtdir, "bin/icuin53.dll"), $target_path
                    elsif File.exists?(File.join($qtdir, "bin/icudt52.dll"))
                      cp File.join($qtdir, "bin/icudt52.dll"), $target_path
                      cp File.join($qtdir, "bin/icuuc52.dll"), $target_path
                      cp File.join($qtdir, "bin/icuin52.dll"), $target_path
                    else
                      cp File.join($qtdir, "bin/icudt51.dll"), $target_path
                      cp File.join($qtdir, "bin/icuuc51.dll"), $target_path
                      cp File.join($qtdir, "bin/icuin51.dll"), $target_path
                    end
                    cp File.join($qtdir, "bin/libEGL.dll"), $target_path
                    cp File.join($qtdir, "bin/libGLESv2.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Core.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Gui.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Network.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Widgets.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5WebKit.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Multimedia.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5MultimediaWidgets.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5WebKitWidgets.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5OpenGL.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5PrintSupport.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Quick.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Qml.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Sql.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Sensors.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5V8.dll"), $target_path
                    if not File.directory?(target_platforms_path)
                      Dir.mkdir(target_platforms_path)
                    end
                    cp File.join($qtdir, "plugins/platforms/qwindows.dll"), target_platforms_path
                    if not File.directory?(target_if_path)
                      Dir.mkdir(target_if_path)
                    end
                    cp File.join($qtdir, "plugins/imageformats/qgif.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qico.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qjpeg.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qmng.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qsvg.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qtga.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qtiff.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qwbmp.dll"), target_if_path
                    
               when 3 # 5.5.0.0
                    format ="Found QT Version : #{$QVersion}"
                    
                    cp File.join($qtdir, "bin/Qt5Core.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5WebKitWidgets.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Widgets.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Gui.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5WebKit.dll"), $target_path
                    cp File.join($qtdir, "bin/icuin54.dll"), $target_path
                    cp File.join($qtdir, "bin/icuuc54.dll"), $target_path
                    cp File.join($qtdir, "bin/icudt54.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Sensors.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Positioning.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Quick.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Qml.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Network.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Multimedia.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5WebChannel.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5Sql.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5MultimediaWidgets.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5OpenGL.dll"), $target_path
                    cp File.join($qtdir, "bin/Qt5PrintSupport.dll"), $target_path
                    if not File.directory?(target_platforms_path)
                      Dir.mkdir(target_platforms_path)
                    end
                    cp File.join($qtdir, "plugins/platforms/qwindows.dll"), target_platforms_path
                    if not File.directory?(target_if_path)
                      Dir.mkdir(target_if_path)
                    end
                    
                    cp File.join($qtdir, "plugins/imageformats/qgif.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qico.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qjpeg.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qmng.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qsvg.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qtga.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qtiff.dll"), target_if_path
                    cp File.join($qtdir, "plugins/imageformats/qwbmp.dll"), target_if_path

                    targetFile = File.join($target_path, $appname + ".exe")
                    if File.exists? targetFile
                      Jake.run3("#{File.join($qtdir, 'bin/windeployqt')} #{targetFile}")
                    else
                      targetFile = File.join($target_path, "Rhodes.exe")
                      if File.exists? targetFile
                        Jake.run3("#{File.join($qtdir, 'bin/windeployqt')} #{targetFile}")
                      else
                        targetFile = File.join($target_path, "RhoLaunch.exe")
                        if File.exists? targetFile
                          Jake.run3("#{File.join($qtdir, 'bin/windeployqt')} #{targetFile}")
                        end
                      end
                    end
               when 4 #5.8.0.0
                   format ="Found QT Version : #{$QVersion}" 
                   targetFile = File.join($target_path, $appname + ".exe")
                    if File.exists? targetFile
                      Jake.run3("#{File.join($qtdir, 'bin/windeployqt')} #{targetFile}")
                    else
                      targetFile = File.join($target_path, "Rhodes.exe")
                      if File.exists? targetFile
                        Jake.run3("#{File.join($qtdir, 'bin/windeployqt')} #{targetFile}")
                      else
                        targetFile = File.join($target_path, "RhoLaunch.exe")
                        if File.exists? targetFile
                          Jake.run3("#{File.join($qtdir, 'bin/windeployqt')} #{targetFile}")
                        end
                      end
                    end
               else
                    format ="Unknown QT Version : #{$QVersion}"
              end
          puts format
    end

    task :extensions => "config:wm" do
      next if $prebuild_win32

      extensions_lib = ''
      pre_targetdeps = ''

      puts "$app_extensions_list : #{$app_extensions_list}"

      $app_extensions_list.each do |ext, commin_ext_path |      
          puts "extension #{ext} [#{commin_ext_path}]"
          next unless commin_ext_path
          
          extpath = File.join(commin_ext_path, 'ext')
          ext_config_path = File.join(commin_ext_path, "ext.yml")
          ext_config = nil
          if File.exist? ext_config_path
            ext_config = Jake.config(File.open(ext_config_path))
          end
          
          project_path = ext_config["project_paths"][$current_platform] if ( ext_config && ext_config["project_paths"] && ext_config["project_paths"][$current_platform])
          next unless (File.exists?( File.join(extpath, "build.bat") ) || project_path)

          if ext != 'openssl.so'
            if ext_config.has_key?('libraries')
              ext_config["libraries"].each { |name_lib|
                extensions_lib << " #{name_lib}.lib"
                pre_targetdeps << " ../../../win32/bin/extensions/#{name_lib}.lib"
              }
            else
              extensions_lib << " #{ext}.lib"
              pre_targetdeps << " ../../../win32/bin/extensions/#{ext}.lib"
            end
          end

          if (project_path)
          
              ENV['RHO_PLATFORM'] = 'win32'
              ENV['PWD'] = $startdir
              ENV['RHO_ROOT'] = $startdir
              ENV['SDK'] = $sdk
              if ext.downcase() == "coreapi" && $rhosimulator_build
                  ENV['RHO_BUILD_CONFIG'] = 'SimulatorRelease'
              else    
                  ENV['RHO_BUILD_CONFIG'] = $rhosimulator_build ? 'Release' : $buildcfg
                  ENV['TARGET_EXT_DIR_SIM'] = File.join($startdir, "platform", 'wm', "bin", $sdk, "rhodes", $rhosimulator_build ? "SimulatorRelease" : $buildcfg)
              end
                    
              ENV['TEMP_FILES_DIR'] = File.join($startdir, "platform", "win32", "bin", "extensions", ext)
              ENV['VCBUILD'] = $vcbuild
              ENV['RHO_PROJECT_PATH'] = File.join(commin_ext_path, project_path)
              ENV['TARGET_TEMP_DIR'] = File.join($startdir, "platform", "win32", "bin", "extensions")
                
              ENV['RHO_EXT_NAME']=ext                

              clean_ext_vsprops(commin_ext_path) if $wm_win32_ignore_vsprops
              Jake.run3('rake --trace', File.join($startdir, 'lib/build/extensions'))
          
          else

              ENV['RHO_PLATFORM'] = 'win32'
              ENV['RHO_BUILD_CONFIG'] = $rhosimulator_build ? 'Release' : $buildcfg
              ENV['PWD'] = $startdir
              ENV['RHO_ROOT'] = ENV['PWD']
              ENV['TARGET_TEMP_DIR'] = File.join(ENV['PWD'], "platform", "win32", "bin", "extensions")
              ENV['TEMP_FILES_DIR'] = File.join(ENV['PWD'], "platform", "win32", "bin", "extensions", ext)
              ENV['VCBUILD'] = $vcbuild
              ENV['SDK'] = $sdk
              ENV['RHO_QMAKE'] = $qmake
              ENV['RHO_QMAKE_VARS'] = $rhosimulator_build ? 'RHOSIMULATOR_BUILD=1' : ''
              ENV['RHO_QMAKE_SPEC'] = $qmake_makespec
              ENV['RHO_VSCMNTOOLS'] = $vscommontools

              clean_ext_vsprops(commin_ext_path) if $wm_win32_ignore_vsprops
              Jake.run3('build.bat', extpath)
          end
      end 
      generate_extensions_pri(extensions_lib, pre_targetdeps)
    end

    def generate_extensions_pri(extensions_lib, pre_targetdeps)
      ext_dir = File.join($startdir, 'platform/win32/bin/extensions')
      mkdir_p ext_dir if not File.exists? ext_dir
      File.open(File.join(ext_dir, 'extensions.pri'), "wb") do |fextensions|
        fextensions.write(%{SOURCES += ../../ruby/ext/rho/extensions.c
LIBS += /LIBPATH:../../../win32/bin/extensions#{extensions_lib}
PRE_TARGETDEPS += #{pre_targetdeps}
})
      end
    end

    #    desc "Build win32 rhobundle"
    #task :rhobundle => ["config:wm", "build:bundle:noxruby", "build:wm:extensions"] do
    #end

    task :rhobundle => ["config:set_win32_platform", "config:wm", "config:qt", "config:win32:qt", "build:wm:rhobundle", :after_bundle] do
    end

    task :upgrade_package => ["build:win32:rhobundle"] do        
      mkdir_p $targetdir if not File.exists? $targetdir
      zip_file_path = File.join($targetdir, "upgrade_bundle.zip")
      Jake.zip_upgrade_bundle( $bindir, zip_file_path)
    end

    task :set_debug_config do
        $buildcfg = 'Debug'
    end

    task :set_release_config do
        $buildcfg = 'Release'
    end

    task :devrhobundle => ["config:set_win32_platform", :set_debug_config, "build:wm:rhobundle", "config:win32:application", :after_bundle] do
    end

    task :after_bundle do
      win32rhopath = ($prebuild_win32 ? $tmpdir : 'platform/wm/bin/win32/rhodes/' + $buildcfg) + '/rho'
      mkdir_p win32rhopath
      namepath = File.join(win32rhopath,"name.txt")
      old_appname = File.read(namepath) if File.exists?(namepath)

      confpath = File.join(win32rhopath,"apps/rhoconfig.txt.changes")
      confpath_content = File.read(confpath) if File.exists?(confpath)

      if $prebuild_win32
        $target_path = $tmpdir
        if not File.directory?($target_path)
          Dir.mkdir($target_path)
        end
        target_rho_dir = File.join($tmpdir, "rho")
        rm_rf target_rho_dir
        mv $srcdir, target_rho_dir
      else
        win32rhopath = win32rhopath + '/'
        rm_rf win32rhopath + 'lib'
        rm_rf win32rhopath + 'apps'
        rm_rf win32rhopath + 'db' if old_appname != $appname

        cp_r $srcdir + '/lib', win32rhopath
        cp_r $srcdir + '/apps', win32rhopath
        cp_r $srcdir + '/db', win32rhopath
      end

      File.open(namepath, "w") { |f| f.write($appname) }
      File.open(confpath, "w") { |f| f.write(confpath_content) }  if old_appname == $appname && confpath_content && confpath_content.length()>0

    end

    task :rhosimulator => ["config:rhosimulator", "config:set_win32_platform", "config:wm", "config:qt", "build:rhosimulator_version", "config:win32:qt"] do
      $config["platform"] = $current_platform
      chdir $startdir
      init_extensions(pwd, nil)
      Rake::Task["build:win32:extensions"].invoke

      cp $startdir + "/res/icons/rhosim.png", $startdir + "/platform/shared/qt/rhodes/resources/rho.png"

      ENV['RHO_QMAKE_SPEC'] = $qmake_makespec
      ENV['RHO_VSCMNTOOLS'] = $vscommontools
      Jake.run3('rhosimulator_win32_build.bat "RHOSIMULATOR_BUILD=1"', $qt_project_dir)

      chdir $startdir

      $target_path = File.join( $startdir, "platform/win32/RhoSimulator/")
      if not File.directory?($target_path)
        Dir.mkdir($target_path)
      end
      cp File.join($startdir, "platform/win32/bin/RhoSimulator/RhoSimulator.exe"), $target_path

      Rake::Task["build:win32:deployqt"].invoke
    end
  end

  #desc "Build rhodes for win32"
  task :win32 => ["build:win32:rhobundle", "config:win32:application"] do
    next if $prebuild_win32

    chdir $config["build"]["wmpath"]

    ENV['RHO_QMAKE_SPEC'] = $qmake_makespec
    ENV['RHO_VSCMNTOOLS'] = $vscommontools
    Jake.run3('rhosimulator_win32_build.bat "DESKTOPAPP_BUILD=1"', $qt_project_dir)

    $target_path = File.join( $startdir, $vcbindir, $sdk, 'rhodes', $buildcfg)
    if not File.directory?($target_path)
      Dir.mkdir($target_path)
    end
    cp File.join($startdir, "platform/win32/bin/RhoSimulator/RhoSimulator.exe"), File.join($target_path, 'rhodes.exe')

    chdir $startdir
  end
end

namespace "device" do

  namespace "wince" do
    desc "Build production for device or emulator"
    task :production => ["config:set_wince_platform", "device:wm:production"] do
    end
  end

  namespace "wm" do
      
    desc 'Creates application container. See also device:wm:apply_container.'
    task :make_container, [:container_prefix_path] => :production do |t, args|
      container_prefix_path = args[:container_prefix_path]

      fail 'container_prefix_path is not set.' if container_prefix_path.nil?

      Dir.glob("#{container_prefix_path}*") {|f| rm_r(f)}
      mkdir_p container_prefix_path

      rhodes_gem_paths = ([
        'platform/wm/RhoLaunch/RhoLaunch.ico',
        'platform/wm/rhodes/resources/icon.ico',
        'platform/wm/bin/**/rhodes.exe',
        'platform/wm/bin/**/RhoLaunch.exe',
        'platform/wm/build/regs.txt'
      ].map {|p| Dir.glob(p)}).flatten

      cp(File.join($app_path, 'build.yml'), container_prefix_path)
      pack_7z($app_path, ['bin/RhoBundle'], File.join(container_prefix_path, 'application_override.7z'))
      pack_7z($startdir, rhodes_gem_paths, File.join(container_prefix_path, 'rhodes_gem_override.7z'))
    end

    desc 'Applies application container. See also device:wm:make_container.'
    task :apply_container, [:container_prefix_path] do |t, args|
      print_timestamp('device:wm:apply_container START')
      container_prefix_path = args[:container_prefix_path]

      File.open(File.join(container_prefix_path, 'build.yml')) do |f|
        container_build_yml = Jake.config(f)
        Jake.normalize_build_yml(container_build_yml)
        $app_config['wm']['webkit_outprocess'] = container_build_yml['wm']['webkit_outprocess']
        WM.config
      end

      unpack_7z($app_path, File.join(container_prefix_path, 'application_override.7z'))
      unpack_7z($startdir, File.join(container_prefix_path, 'rhodes_gem_override.7z'))
      print_timestamp('device:wm:apply_container FINISH')
    end

    task :apply_container_jsapi, [:container_prefix_path] do |t, args|
      print_timestamp('device:wm:apply_container_jsapi START')
      container_prefix_path = args[:container_prefix_path]
      unpack_7z_path($app_path, File.join(container_prefix_path, 'application_override.7z'), "bin/RhoBundle/apps/public/api")
      print_timestamp('device:wm:apply_container_jsapi END')
    end

    desc 'Build cab'
    task :cab => ['config:wm'] do
      print_timestamp('device:wm:cab START')
      Jake.make_rhoconfig_txt
      stuff_around_appname
      build_cab
      print_timestamp('device:wm:cab FINISH')
    end

    desc "Build production for device or emulator"
    task :production, [:exclude_dirs] => ["config:wm","build:wm:rhobundle","build:wm:rhodes"] do
      print_timestamp('device:wm:production START')
      if $use_shared_runtime
        rm_rf $srcdir + '/lib'
      end

      wm_icon = $app_path + '/icon/icon.ico'

      icon_dest = $srcdir + '/icon'
      rm_rf icon_dest
      if $use_shared_runtime
        if File.exists? wm_icon
          mkdir_p icon_dest
          cp wm_icon, icon_dest
        end
      end

      if !$use_shared_runtime
        build_rholaunch

        out_dir = $startdir + "/" + $vcbindir + "/#{$sdk}" + "/rhodes/Release/"
        out_rholauch_dir = $startdir + "/" + $vcbindir + "/#{$sdk}" + "/RhoLaunch/Release/"
        cp out_rholauch_dir + "RhoLaunch.exe", out_dir + "RhoLaunch.exe"
      end

      stuff_around_appname

      build_cab if $build_cab
      print_timestamp('device:wm:production FINISH')
    end

    task :production_with_prebuild_binary => ['config:wm'] do
      print_timestamp('device:wm:production_with_prebuild_binary START')
      #Support build.yml settings on cloud by copying to rhoconfig.txt
      Rake::Task['config:common:ymlsetup'].invoke
      container_path = determine_prebuild_path_win('wm', $app_config)
      $skip_build_extensions = true
      $skip_build_js_api_files = true
      Rake::Task['device:wm:apply_container'].invoke(container_path)
      Rake::Task['build:bundle:noxruby'].invoke
      Rake::Task['device:wm:apply_container_jsapi'].invoke(container_path)
      Rake::Task['device:wm:cab'].invoke
      print_timestamp('device:wm:production_with_prebuild_binary FINISH')
    end
  end

  def createWin32Production(skip_deployqt = false, skip_nsis = false)
    out_dir = $startdir + "/" + $vcbindir + "/#{$sdk}" + "/rhodes/" + $buildcfg + "/"
    puts "out_dir - "  + out_dir

    mkdir_p $targetdir unless skip_nsis
    mkdir_p $tmpdir unless skip_deployqt
    mkdir_p out_dir

    cp out_dir + "rhodes.exe", $tmpdir + "/" + $appname + ".exe"

    script_name = File.join($startdir, "platform", "wm", "build", "rhodes.nsi")
    app_script_name = File.join($tmpdir, $appname + ".nsi")

    license_filename = "LICENSE.txt"
    license_file = File.join($app_path, license_filename)
    license_present = '#'
    license_line = ''
    if File.exists? license_file
      cp license_file, $tmpdir
      license_present = ''
      license_line = 'File "' + license_filename + '"'
    end

    readme_filename = "README.html"
    readme_file = File.join($app_path, readme_filename)
    readme_present = '#'
    readme_line = '#'
    if File.exists? readme_file
      cp readme_file, $tmpdir
      readme_present = ''
      readme_line = 'File "' + readme_filename + '"'
    end

    if !skip_nsis
      vspec_files = ''
       if Jake.getBuildBoolProp('deployqt', $app_config, true)
         #vspec_files += "  File /r \"imageformats\"\n"
          #if($qtversionindex.nil? || $qtversionindex > 1)
             #vspec_files += "  File /r \"platforms\"\n"
          #end
          vspec_files += "  File /r *.dll\n"
       end
      if Jake.getBuildBoolProp('deploymsvc', $app_config, true) && ($vs_version == 2008)
        vspec_files += "  File *.manifest\n"
      end

      # custumize install script for application
      $appdisplay_version=$app_version + '.0.0'
      if $app_config.has_key?('vendor')
       $vendorname = $app_config["vendor"]
       else
       $vendorname = "Zebra Technologies"
       end
      install_script = File.read(script_name)
      install_script = install_script.gsub(/%OUTPUTFILE%/, $targetdir + "/" + $appname + "-setup.exe" )
      install_script = install_script.gsub(/%APPNAME%/, $appname)
      install_script = install_script.gsub(/%APPVERSION%/, $app_version)
      install_script = install_script.gsub(/%APPDISPLAYVERSION%/, $appdisplay_version)
      install_script = install_script.gsub(/%APP_EXECUTABLE%/, $appname + ".exe") 
      install_script = install_script.gsub(/%SECTOIN_TITLE%/, "\"This installs " + $appname + "\"")
      install_script = install_script.gsub(/%FINISHPAGE_TEXT%/, "\"Thank you for installing " + $appname + " \\r\\n\\n\\n\"")
      install_script = install_script.gsub(/%APPINSTALLDIR%/, "C:\\" + $appname)
      install_script = install_script.gsub(/%APPICON%/, "icon.ico")
      install_script = install_script.gsub(/%GROUP_NAME%/, $vendorname)
      install_script = install_script.gsub(/%SECTION_NAME%/, "\"" + $appname + "\"")
      install_script = install_script.gsub(/%LICENSE_FILE%/, license_line)
      install_script = install_script.gsub(/%LICENSE_PRESENT%/, license_present)
      install_script = install_script.gsub(/%README_FILE%/, readme_line)
      install_script = install_script.gsub(/%README_PRESENT%/, readme_present)
      install_script = install_script.gsub(/%QT_VSPEC_FILES%/, vspec_files)
      install_script = install_script.gsub(/%VENDOR%/, $vendorname)
      File.open(app_script_name, "w") { |file| file.puts install_script }
    end

    puts "$appname - " + $appname

    cp $app_icon_path, $tmpdir + "/icon.ico"
    cp $qt_icon_path, $tmpdir + "/icon.png"

    if !skip_nsis
      File.open(File.join($targetdir,"app_info.txt"), "w") { |f| f.write( $vendorname + "/" + $appname + "/" + $appname + ".exe") }
    end

    chdir $tmpdir

    if !skip_deployqt
      target_rho_dir = File.join($tmpdir, "rho")
      rm_rf target_rho_dir
      mv $srcdir, target_rho_dir
    end

    $target_path = $tmpdir
    Rake::Task["build:win32:deployqt"].invoke unless skip_deployqt

    if !skip_nsis
      puts "$nsis - " + $nsis
      args = ['"' + $tmpdir + "/" + $appname + ".nsi\""]
      puts "arg = " + args.to_s
      puts Jake.run2($nsis, args, {:nowait => false} )
    end
  end

  namespace "winxpe" do
    desc "Build installer for Windows XP Embedded"
    task :production do     
      $winxpe_build = true
      Rake::Task["device:win32:production"].invoke  
    end
  end

  namespace "win32" do
    desc "Build installer for Windows"
    task :production => ["build:win32:set_release_config", "build:win32"] do
      createWin32Production()
    end

    desc "Build Windows for production, use prebuild binaries"
    task :production_with_prebuild_binary do
      $prebuild_win32 = true
      Rake::Task["device:win32:build_with_prebuild_binary"].invoke
    end
    task :build_with_prebuild_binary => ["build:win32:set_release_config", "build:win32:rhobundle", "config:win32:application"] do
      container_path = determine_prebuild_path_win('win32', $app_config)

      #Support build.yml settings on cloud by copying to rhoconfig.txt
      Rake::Task['config:common:ymlsetup'].invoke

      Rake::Task['device:win32:apply_container'].invoke(container_path)
      createWin32Production(true,false)
    end

    desc 'Creates application container. See also device:win32:apply_container.'
    task :make_container, [:container_prefix_path] => ["build:win32:set_release_config", "build:win32"] do |t, args|
      createWin32Production(false,true)

      container_prefix_path = args[:container_prefix_path]

      Dir.glob("#{container_prefix_path}*") {|f| rm_r(f)}
      mkdir_p container_prefix_path

      cd $startdir
      rhodes_gem_paths = ([
        'platform/wm/bin/win32/rhodes/**/rhodes.exe'
      ].map {|p| Dir.glob(p)}).flatten
      bin_exclude_files = [
        'bin/tmp/*.exe',
        'bin/tmp/*.time',
        'bin/tmp/*.ico',
        'bin/tmp/*.png',
        'bin/tmp/rho/RhoBundleMap.txt',
        'bin/tmp/rho/apps/rhoconfig.txt*',
        'bin/tmp/rho/apps/rhofilelist.txt',
        'bin/tmp/rho/apps/app',
        'bin/tmp/rho/apps/app_manifest.txt',
        'bin/tmp/rho/apps/public/public.txt'
      ]

      pack_7z($app_path, ['bin'], File.join(container_prefix_path, 'application_override.7z'), bin_exclude_files)
      pack_7z($startdir, rhodes_gem_paths, File.join(container_prefix_path, 'rhodes_gem_override.7z'))
    end

    desc 'Applies application container. See also device:win32:make_container'
    task :apply_container, [:container_prefix_path] do |t, args|
      container_prefix_path = args[:container_prefix_path]

      unpack_7z($app_path, File.join(container_prefix_path, 'application_override.7z'))
      unpack_7z($startdir, File.join(container_prefix_path, 'rhodes_gem_override.7z'))
    end

  end
end

namespace "clean" do

  desc "Clean windows ce"
  task :wince => "clean:wince:all" do
  end

  desc "Clean wm"
  task :wm => "clean:wm:all" do
  end

  namespace "wince" do
    task :rhodes => ["config:set_wince_platform", "config:wm"] do
      rm_rf $vcbindir + "/#{$sdk}"
      rm_rf $targetdir
      
      rm_rf File.join($app_path, "bin/tmp") if File.exists? File.join($app_path, "bin/tmp")
      rm_rf File.join($app_path, "bin/RhoBundle") if File.exists? File.join($app_path, "bin/RhoBundle")
      
    end
    task :all => ["clean:wince:rhodes", "clean:common"]
  end

  namespace "wm" do
    task :rhodes => ["config:wm"] do
      rm_rf $vcbindir + "/#{$sdk}"
      rm_rf $targetdir
      
      rm_rf File.join($app_path, "bin/tmp") if File.exists? File.join($app_path, "bin/tmp")
      rm_rf File.join($app_path, "bin/RhoBundle") if File.exists? File.join($app_path, "bin/RhoBundle")
      
    end
    task :all => ["clean:wm:rhodes", "clean:common"]
  end

  desc "Clean win32"
  task :win32 => ["config:set_win32_platform", "config:wm", "clean:common"]do
    rm_rf $vcbindir + "/win32"
    rm_rf $tmpdir
    rm_rf $targetdir
    rm_rf File.join($startdir, 'platform/shared/qt/rhodes/GeneratedFiles')
    rm_rf File.join($startdir, 'platform/win32/bin')
    rm_rf File.join($startdir, 'platform/wm/bin')
    
    rm_rf File.join($app_path, "bin/tmp") if File.exists? File.join($app_path, "bin/tmp")
    rm_rf File.join($app_path, "bin/RhoBundle") if File.exists? File.join($app_path, "bin/RhoBundle")
    
  end
  
  desc "Clean winxpe"
  task :winxpe => ["clean:win32"]do
  end
  
end

namespace "run" do
  
  task :mylogserver => ["config:wm"] do
    Jake.run_rho_log_server($app_path)
  end

  def gelLogPath
    log_file_path =  File.join($app_path, $log_file)
    return log_file_path
  end

  task :wince  do
    puts "Windows CE emulator not working on windows system."
  end

  desc "Build and run on WM6 emulator"
  task :wm => ["config:wm","build:wm:rhobundle","build:wm:rhodes"] do 

    if $use_direct_deploy == "no" 
      Rake::Task["device:wm:production"].execute
      Rake::Task["run:wm:cab"].execute
    else
      $build_cab = false
      Rake::Task["device:wm:production"].execute
      
      # kill all running detool
      kill_detool

      cd $startdir + "/res/build-tools"
      detool = "detool.exe"
    
      puts "\nStarting application on the WM6 emulator\n\n"
      log_file = gelLogPath

      File.delete($app_path + "/started")  if File.exists?($app_path + "/started")
      Jake.run_rho_log_server($app_path)
      puts "Start Log Server. Wating while Log Server is started..."
      while true do
        if File.exists?($app_path + "/started")
          break
        end
        sleep(1)
      end

      cs = CheckSumComparer.new($tmp_dir, File.join($startdir, $vcbindir, $sdk) )
      exe_changed = cs.compare

      if $webkit_capability and !$use_shared_runtime
        wk_args   = [$detoolappflag, 'wk-emu', "\"#{$wm_emulator}\"", '"'+ $wk_data_dir.gsub(/"/,'\\"') + '"', '"'+ $appname + '"']
        Jake.run2( detool, wk_args, {:nowait => false})
      end

      additional_dlls_paths.each do |path|
        add_files_args   = [$detoolappflag, 'wk-emu', "\"#{$wm_emulator}\"", '"'+ path.gsub(/"/,'\\"') + '"', '"'+ $appname + '"']
        Jake.run2( detool, add_files_args, {:nowait => false})
      end

      args = [$detoolappflag, 'emu', exe_changed ? "1" : "0", "\"#{$wm_emulator}\"", '"'+$appname.gsub(/"/,'\\"')+'"', '"'+$srcdir.gsub(/"/,'\\"')+'"', '"'+($use_shared_runtime ? $srcdir + '/../' + $appname + '.lnk' : $startdir + "/" + $vcbindir + "/#{$sdk}" + "/rhodes/Release/" + $appname + ".exe").gsub(/"/,'\\"')+'"' , $port]
      Jake.run2( detool, args, {:nowait => false})
    end
  end

  namespace "wince" do
    task :get_log => "run:wm" do
    end

    rhosim_task = lambda do |name, &block|
      task name => ["config:set_wince_platform", "config:common"] do
        $rhosim_config = "platform='wm'\r\n"
        block.()
      end
    end

    desc "Run application on RhoSimulator"
    rhosim_task.(:rhosimulator) { Rake::Task["run:rhosimulator"].invoke }
    namespace :rhosimulator do
      rhosim_task.(:build) { Rake::Task["run:rhosimulator:build"].invoke         }
      rhosim_task.(:debug) { Rake::Task["run:rhosimulator:run"  ].invoke('wait') }
    end

    desc "Build and run on the Windows CE device"
    task :device => ["config:set_wince_platform", "run:wm:device"] do
    end

    namespace "device" do
      desc "Build, install .cab and run on the Windows CE device"
      task :cab => ["config:set_wince_platform", "run:wm:device:cab"] do
      end
    end
  end
  
  namespace "wm" do
    task :get_log => "config:wm" do
      puts "log_file=" + gelLogPath
    end

    rhosim_task = lambda do |name, &block|
      task name => ["config:set_wm_platform", "config:common"] do
        $rhosim_config = "platform='wm'\r\n"
        block.()
      end
    end

    desc "Run application on RhoSimulator"
    rhosim_task.(:rhosimulator) { Rake::Task["run:rhosimulator"].invoke }
    namespace :rhosimulator do
      rhosim_task.(:build) { Rake::Task["run:rhosimulator:build"].invoke         }
      rhosim_task.(:debug) { Rake::Task["run:rhosimulator:run"  ].invoke('wait') }
    end


    desc "Build and run on the Windows Mobile device"
    task :device  => ["config:wm","build:wm:rhobundle","build:wm:rhodes"] do 
        

      if $use_direct_deploy == "no" 
        Rake::Task["device:wm:production"].invoke
        Rake::Task["run:wm:device:cab"].execute
      else
        $build_cab = false
        Rake::Task["device:wm:production"].invoke
          
        # kill all running detool
        kill_detool

        cd $startdir + "/res/build-tools"
        detool = "detool.exe"     

        puts "\nStarting application on the device"
        puts "Please, connect you device via ActiveSync.\n\n"
        log_file = gelLogPath

        File.delete($app_path + "/started")  if File.exists?($app_path + "/started")

        if Jake.getBool(ENV["no_remote_log"]) == false
          Jake.run_rho_log_server($app_path)
          puts "RhoLogServer is starting"
          while true do
            if File.exists?($app_path + "/started")
              break
            end
            sleep(1)
          end    
        end

        if $webkit_capability and !$use_shared_runtime
          wk_args   = [$detoolappflag, 'wk-dev', '"'+ $wk_data_dir.gsub(/"/,'\\"') + '"', '"'+ $appname + '"']
          Jake.run2( detool, wk_args, {:nowait => false})
        end

        additional_dlls_paths.each do |path|
          add_files_args   = [$detoolappflag, 'wk-dev', '"'+ path.gsub(/"/,'\\"') + '"', '"'+ $appname + '"']
          Jake.run2( detool, add_files_args, {:nowait => false})
        end

        cs = CheckSumComparer.new($tmp_dir, File.join($startdir, $vcbindir, $sdk) )
        exe_changed = cs.compare

        args = [$detoolappflag, 'dev', exe_changed ? "1" : "0", '"'+$appname.gsub(/"/,'\\"')+'"', '"'+$srcdir.gsub(/"/,'\\"')+'"', '"'+($use_shared_runtime ? $srcdir + '/../' + $appname + '.lnk' : $startdir + "/" + $vcbindir + "/#{$sdk}" + "/rhodes/Release/" + $appname + ".exe").gsub(/"/,'\\"')+'"', $port]
        Jake.run2( detool, args, {:nowait => false})
      end
    end

    task :spec, [:exclude_dirs] => [] do

        Jake.decorate_spec do

            Rake::Task['device:wm:production'].invoke

            # kill all running detool
            kill_detool

            cd $startdir + "/res/build-tools"
            detool = "detool.exe"
            
            if $webkit_capability and !$use_shared_runtime
              wk_args   = [$detoolappflag, 'wk-dev', '"'+ $wk_data_dir.gsub(/"/,'\\"') + '"', '"'+ $appname + '"']
              Jake.run2( detool, wk_args, {:nowait => false})
            end

            additional_dlls_paths.each do |path|
              add_files_args   = [$detoolappflag, 'wk-dev', '"'+ path.gsub(/"/,'\\"') + '"', '"'+ $appname + '"']
              Jake.run2( detool, add_files_args, {:nowait => false})
            end

            args = [$detoolappflag, 'dev', '"'+$appname.gsub(/"/,'\\"')+'"', '"'+$srcdir.gsub(/"/,'\\"')+'"', '"'+($use_shared_runtime ? $srcdir + '/../' + $appname + '.lnk' : $startdir + "/" + $vcbindir + "/#{$sdk}" + "/rhodes/Release/" + $appname + ".exe").gsub(/"/,'\\"')+'"', $port]
     
            puts "\nStarting application on the WM6 emulator\n\n"
            log_file = gelLogPath

            #remove log file
            rm_rf log_file if File.exists?(log_file)

            File.delete($app_path + "/started")  if File.exists?($app_path + "/started")
            Jake.run_rho_log_server($app_path)
            puts "RhoLogServer is starting"
            while true do
              if File.exists?($app_path + "/started")
                break
              end
              sleep(1)
            end

            Jake.before_run_spec
            start = Time.now

            Jake.run2( detool, args, {:nowait => false})

            puts "waiting for log: " + log_file

            for i in 0..120
              if !File.exist?(log_file)
                sleep(1)
              else
              break
              end
            end

          if !File.exist?(log_file)
            puts "Can not read log file: " + log_file
            exit(1)
            end

            puts "start read log"

            io = File.new(log_file, "r")
            waiting_count = 0
            end_spec = false
            while !end_spec do
                line_count = 0
                io.each do |line|
                    #puts line
                    end_spec = !Jake.process_spec_output(line)
                    break if end_spec
                    line_count += 1
                end
                if line_count==0
                    waiting_count += 1
                else
                    waiting_count = 0
                end
                if waiting_count > 600
                    puts "spec application hung (600 seconds timeout)"
                    end_spec = true
                end
                sleep(1) unless end_spec
            end
            io.close

            Jake.process_spec_results(start)

            $stdout.flush
            chdir $startdir

        end

    end

    namespace "device" do
      desc "Build, install .cab and run on the Windows Mobile device"
      task :cab => ["device:wm:production"] do
        # kill all running detool
        kill_detool

        cd $startdir + "/res/build-tools"
        detool = "detool.exe"
        args   = [$detoolappflag, 'devcab', '"' + $targetdir + '/' +  $appname + ".cab\"", '"' + $appname + '"', ( $use_shared_runtime ? "1" : "0")]
        puts "\nStarting application on the device"
        puts "Please, connect you device via ActiveSync.\n\n"
        log_file = gelLogPath

        # temporary disable log from device (caused enormous delays)
        # Jake.run2( detool, ['log', log_file, $port], {:nowait => true})
        Jake.run(detool,args)
      end
    end

    desc "Build, install .cab and run on WM6 emulator"
    task :cab => ["device:wm:production"] do
      # kill all running detool
      kill_detool

      cd $startdir + "/res/build-tools"
      detool = "detool.exe"
      args   = [$detoolappflag, 'emucab', "\"#{$wm_emulator}\"", '"' + $targetdir + '/' +  $appname + ".cab\"", '"' + $appname + '"', ( $use_shared_runtime ? "1" : "0")]
      log_file = gelLogPath

      Jake.run2( detool, ['log', log_file, $port], {:nowait => true})

      puts "\nStarting application on the WM6 emulator\n\n"
      Jake.run(detool,args)
    end

    desc "Install .cab and run on the Windows Mobile device"
    task "device:package", [:package_path] => ["config:wm"] do |t, args|

      cab_path = args.package_path

      fail "Wrong cab file path #{cab_path.inspect}" if cab_path.nil? || cab_path.empty? || !File.exists?(cab_path)

      # kill all running detool
      kill_detool

      cd $startdir + "/res/build-tools"
      detool = "detool.exe"
      args   = [$detoolappflag, 'devcab', %Q["#{cab_path}"], '"' + $appname + '"', ( $use_shared_runtime ? "1" : "0")]
      puts "\nStarting application on the device"
      puts "Please, connect you device via ActiveSync.\n\n"
      log_file = gelLogPath

      # temporary disable log from device (caused enormous delays)
      # Jake.run2( detool, ['log', log_file, $port], {:nowait => true})
      Jake.run(detool,args)
    end

    desc "Install .cab and run on the Windows Mobile emulator"
    task "simulator:package", [:package_path] => ["config:wm"] do |t, args|

      cab_path = args.package_path

      fail "Wrong cab file path #{cab_path.inspect}" if cab_path.nil? || cab_path.empty? || !File.exists?(cab_path)

      # kill all running detool
      kill_detool

      cd $startdir + "/res/build-tools"
      detool = "detool.exe"
      args   = [$detoolappflag, 'emucab', %Q["#{cab_path}"], '"' + $appname + '"', ( $use_shared_runtime ? "1" : "0")]
      puts "\nStarting application on the device"
      puts "Please, connect you device via ActiveSync.\n\n"
      log_file = gelLogPath

      # temporary disable log from device (caused enormous delays)
      # Jake.run2( detool, ['log', log_file, $port], {:nowait => true})
      Jake.run(detool,args)
    end
  end

  desc "Run win32"
  task :win32 => ["build:win32"] do
    unless $prebuild_win32
      rundir = $config["build"]["wmpath"]
      $target_path = File.join( rundir, "bin/win32/rhodes", $buildcfg )
      exefile = "bin\\win32\\rhodes\\" + $buildcfg + "\\rhodes.exe"
    else
      rundir = $target_path
      exefile = $target_path + '/' + $appname + '.exe'
    end

    Rake::Task["build:win32:deployqt"].invoke unless $prebuild_win32

    cp $qt_icon_path, $target_path + "/icon.png"

    args = [' ']
    #    chdir rundir
    #    Thread.new { Jake.run("bin\\win32\\rhodes\\Debug\\rhodes", args) }
    Jake.run2 exefile, args, {:directory => rundir, :nowait => true}

    $stdout.flush
    chdir $startdir

    unless $? == 0
      puts "Error to run rhodes for win32"
      exit 1
    end
  end

  namespace "rhosimulator" do
    task :get_log => "config:common" do
      $log_file = $app_config["applog"].nil? ? "applog.txt" : $app_config["applog"]
      puts "log_file=" + File.join($app_path, "rhosimulator", $log_file)
    end
  end

  namespace "win32" do
    rhosim_task = lambda do |name, &block|
      task name => ["config:set_win32_platform", "config:common"] do
        $rhosim_config = "platform='win32'\r\n"
        block.()
      end
    end

    desc "Run application on RhoSimulator"
    rhosim_task.(:rhosimulator) { Rake::Task["run:rhosimulator"].invoke }
    namespace :rhosimulator do
      rhosim_task.(:build) { Rake::Task["run:rhosimulator:build"].invoke         }
      rhosim_task.(:debug) { Rake::Task["run:rhosimulator:run"  ].invoke('wait') }
    end

    task :package do
      $prebuild_win32 = true
      Rake::Task["run:win32:run_with_prebuild_binary"].invoke
    end

    task :run_with_prebuild_binary => ["build:win32:set_release_config", "build:win32:rhobundle", "config:win32:application"] do
      container_path = determine_prebuild_path_win('win32', $app_config)
      Rake::Task['device:win32:apply_container'].invoke(container_path)

      createWin32Production(true,true)

      Rake::Task['run:win32'].invoke()
    end

    task :delete_db do
      $buildcfg = $app_config["buildcfg"]
      $buildcfg = "Release" unless $buildcfg
    
      db_path = 'platform/wm/bin/win32/rhodes/' + $buildcfg + '/rho/db'
      rm_rf db_path if File.exists?(db_path)
    end

    task :spec => [:delete_db] do

      Jake.decorate_spec do

        Rake::Task['build:win32'].invoke

        #remove log file
        win32rhopath = 'platform/wm/bin/win32/rhodes/' + $buildcfg + '/rho/'
        win32logpath = File.join(win32rhopath,"RhoLog.txt")
        win32logpospath = File.join(win32rhopath,"RhoLog.txt_pos")
        win32configpath = File.join(win32rhopath,"apps/rhoconfig.txt.changes")
        rm_rf win32logpath if File.exists?(win32logpath)
        rm_rf win32logpospath if File.exists?(win32logpospath)
        rm_rf win32configpath if File.exists?(win32configpath)

        Jake.before_run_spec
        start = Time.now

        args = [' ']
        Jake.run2( "bin\\win32\\rhodes\\" + $buildcfg + "\\rhodes.exe", args, {:directory => $config["build"]["wmpath"], :nowait => false}) do |line|
          Jake.process_spec_output(line)
        end
        Jake.process_spec_results(start)

        $stdout.flush
        chdir $startdir
      end
    end

  end

end

namespace 'stop' do
  task :win32 => ['config:wm'] do
    Jake.get_process_list.each do |p|
      next unless p[:cmd] =~ /^bin\\win32\\rhodes\\#{$buildcfg}\\rhodes\.exe /
      Jake.run2('taskkill.exe', ['/F', '/PID', p[:pid]], {:hide_output => true})
    end
  end
end

