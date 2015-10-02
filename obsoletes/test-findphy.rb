
def get_first_iw_phy
  io = IO.popen("sudo iw phy | grep Wiphy")
  data = io.read
  io.close

  phys = data.split(/^Wiphy /).map{|str| str.strip}.select{|str| str.match(/^phy\d+$/) }
  return phys[0]
end

def get_first_iw_dev
  io = IO.popen("sudo iw dev | grep Interface")
  data = io.read
  io.close
  devs = data.split(/Interface /).map{|str| str.strip}.select{|str| str.match(/^wlan\d$/)}
  return devs[0]
end

p get_first_iw_phy
p get_first_iw_dev
