from os import system, listdir, statvfs, popen, makedirs, readlink, stat, major, minor
from Tools.Directories import SCOPE_HDD, resolveFilename
from Tools.CList import CList
from SystemInfo import SystemInfo
import time
from Components.Console import Console

def tryOpen(filename):
	try:
		procFile = open(filename)
	except IOError:
		return ""
	return procFile

class Harddisk:
	def __init__(self, device):
		self.device = device
		procfile = tryOpen("/sys/block/"+self.device+"/dev")
		tmp = procfile.readline().split(':')
		s_major = int(tmp[0])
		s_minor = int(tmp[1])
		self.max_idle_time = 0
		self.idle_running = False
		self.timer = None
#--->
#-		for disc in listdir("/dev/discs"):
#-			path = readlink('/dev/discs/'+disc)
#-			devidex = '/dev/discs/'+disc+'/'
#-			devidex2 = '/dev'+path[2:]+'/'
#-			disc = devidex2+'disc'
#--->
#+++>
		for disc in ['sda', 'sdb', 'sdc', 'sdd', 'sr0', 'sr1']:# listdir("/dev/discs"):
			devidex = '/dev/'+ disc
			disc = devidex
			devidex2 = devidex
#+++<
			ret = stat(disc).st_rdev
			if s_major == major(ret) and s_minor == minor(ret):
				self.devidex = devidex
				self.devidex2 = devidex2
				print "new Harddisk", device, '->', self.devidex, '->', self.devidex2
				self.startIdle()
				break

	def __lt__(self, ob):
		return self.device < ob.device

	def stop(self):
		if self.timer:
			self.timer.stop()
			self.timer.callback.remove(self.runIdle)

	def bus(self):
		ide_cf = self.device[:2] == "hd" and "host0" not in self.devidex2 # 7025 specific
		internal = self.device[:2] == "hd"
		if ide_cf:
			ret = "External (CF)"
		elif internal:
			ret = "Internal"
		else:
			ret = "External"
		return ret

	def diskSize(self):
		procfile = tryOpen("/sys/block/"+self.device+"/size")
		if procfile == "":
			return 0
		line = procfile.readline()
		procfile.close()
		try:
			cap = int(line)
		except:
			return 0;
		return cap / 1000 * 512 / 1000

	def capacity(self):
		cap = self.diskSize()
		if cap == 0:
			return ""
		return "%d.%03d GB" % (cap/1000, cap%1000)

	def model(self):
		if self.device[:2] == "hd":
			procfile = tryOpen("/proc/ide/"+self.device+"/model")
			if procfile == "":
				return ""
			line = procfile.readline()
			procfile.close()
			return line.strip()
		elif self.device[:2] == "sd":
			procfile = tryOpen("/sys/block/"+self.device+"/device/vendor")
			if procfile == "":
				return ""
			vendor = procfile.readline().strip()
			procfile.close()
			procfile = tryOpen("/sys/block/"+self.device+"/device/model")
			model = procfile.readline().strip()
			return vendor+'('+model+')'
		else:
			assert False, "no hdX or sdX"

	def free(self):
		procfile = tryOpen("/proc/mounts")
		
		if procfile == "":
			return -1

		free = -1
		while 1:
			line = procfile.readline()
			if line == "":
				break
			if line.startswith(self.devidex) or line.startswith(self.devidex2):
				parts = line.strip().split(" ")
				try:
					stat = statvfs(parts[1])
				except OSError:
					continue
				free = stat.f_bfree/1000 * stat.f_bsize/1000
				break
		procfile.close()
		return free

	def numPartitions(self):
		try:
			idedir = listdir(self.devidex)
		except OSError:
			return -1
		numPart = -1
		for filename in idedir:
			if filename.startswith("disc"):
				numPart += 1
			if filename.startswith("part"):
				numPart += 1
		return numPart

	def unmount(self):
		procfile = tryOpen("/proc/mounts")

		if procfile == "":
			return -1

		cmd = "/bin/umount"

		for line in procfile:
			if line.startswith(self.devidex) or line.startswith(self.devidex2):
				parts = line.split()
				cmd = ' '.join([cmd, parts[1]])

		procfile.close()

		res = system(cmd)
		return (res >> 8)

	def createPartition(self):
#--->
#-		cmd = "/sbin/sfdisk -f " + self.devidex + "disc"
#---<
#+++>
		cmd = "/sbin/sfdisk -f " + self.devidex
#+++<
		sfdisk = popen(cmd, "w")
		sfdisk.write("0,\n;\n;\n;\ny\n")
		sfdisk.close()
		return 0

	def mkfs(self):
		cmd = "/sbin/mkfs.ext3 "
		if self.diskSize() > 4 * 1024:
			cmd += "-T largefile "
#--->
#-		cmd += "-m0 -O dir_index " + self.devidex + "part1"
#---<
#+++>
		cmd += "-m0 " + self.devidex + "1"
#+++<
		res = system(cmd)
		return (res >> 8)

	def mount(self):
		res = -1
		#we don't know which type of devicename is used in fstab, try both
		for device in [self.devidex, self.devidex2]:
#--->
#-			cmd = "/bin/mount -t ext3 " + device + "part1"
#---<
#+++>
			cmd = "/bin/mount -t ext3 " + self.devidex + "1"
#+++<
			res = system(cmd)
			res >>= 8
			if not res:
				break
		return res

	def createMovieFolder(self):
		try:
			makedirs(resolveFilename(SCOPE_HDD))
		except OSError:
			return -1
		return 0

	def fsck(self):
		# We autocorrect any failures
		# TODO: we could check if the fs is actually ext3
#--->
#-		cmd = "/sbin/fsck.ext3 -f -p " + self.devidex + "part1"
#---<
#+++>
		cmd = "/sbin/fsck.ext3 -f -p " + self.devidex + "1"
#+++<
		res = system(cmd)
		return (res >> 8)

	errorList = [ _("Everything is fine"), _("Creating partition failed"), _("Mkfs failed"), _("Mount failed"), _("Create movie folder failed"), _("Fsck failed"), _("Please Reboot"), _("Filesystem contains uncorrectable errors"), _("Unmount failed")]

	def initialize(self):
		self.unmount()

		if self.createPartition() != 0:
			return -1

		if self.mkfs() != 0:
			return -2

		if self.mount() != 0:
			return -3

		if self.createMovieFolder() != 0:
			return -4

		return 0

	def check(self):
		self.unmount()

		res = self.fsck()
		if res & 2 == 2:
			return -6

		if res & 4 == 4:
			return -7

		if res != 0 and res != 1:
			# A sum containing 1 will also include a failure
			return -5

		if self.mount() != 0:
			return -3

		return 0
	
	def getDeviceDir(self):
		return self.devidex
	
	def getDeviceName(self):
#--->
#-		return self.getDeviceDir() + "disc"
#---<
#+++>
		return self.getDeviceDir()
#+++<

	# the HDD idle poll daemon.
	# as some harddrives have a buggy standby timer, we are doing this by hand here.
	# first, we disable the hardware timer. then, we check every now and then if
	# any access has been made to the disc. If there has been no access over a specifed time,
	# we set the hdd into standby.
	def readStats(self):
		l = open("/sys/block/%s/stat" % self.device).read()
		(nr_read, _, _, _, nr_write) = l.split()[:5]
		return int(nr_read), int(nr_write)

	def startIdle(self):
		self.last_access = time.time()
		self.last_stat = 0
		self.is_sleeping = False
		from enigma import eTimer

		# disable HDD standby timer
#--->
#-		Console().ePopen(("hdparm", "hdparm", "-S0", (self.devidex + "disc")))
#---<
#+++>
		Console().ePopen(("hdparm", "hdparm", "-S0", self.devidex))
#+++<
		self.timer = eTimer()
		self.timer.callback.append(self.runIdle)
		self.idle_running = True
		self.setIdleTime(self.max_idle_time) # kick the idle polling loop

	def runIdle(self):
		if not self.max_idle_time:
			return
		t = time.time()

		idle_time = t - self.last_access

		stats = self.readStats()
		print "nr_read", stats[0], "nr_write", stats[1]
		l = sum(stats)
		print "sum", l, "prev_sum", self.last_stat

		if l != self.last_stat: # access
			print "hdd was accessed since previous check!"
			self.last_stat = l
			self.last_access = t
			idle_time = 0
			self.is_sleeping = False
		else:
			print "hdd IDLE!"

		print "[IDLE]", idle_time, self.max_idle_time, self.is_sleeping
		if idle_time >= self.max_idle_time and not self.is_sleeping:
			self.setSleep()
			self.is_sleeping = True

	def setSleep(self):
#--->
#-		Console().ePopen(("hdparm", "hdparm", "-y", (self.devidex + "disc")))
#---<
#+++>
		Console().ePopen(("hdparm", "hdparm", "-y", self.devidex ))
#+++<

	def setIdleTime(self, idle):
		self.max_idle_time = idle
		if self.idle_running:
			if not idle:
				self.timer.stop()
			else:
				self.timer.start(idle * 100, False)  # poll 10 times per period.

	def isSleeping(self):
		return self.is_sleeping

class Partition:
	def __init__(self, mountpoint, device = None, description = "", force_mounted = False):
		self.mountpoint = mountpoint
		self.description = description
		self.force_mounted = force_mounted
		self.is_hotplug = force_mounted # so far; this might change.
		self.device = device

	def stat(self):
		return statvfs(self.mountpoint)

	def free(self):
		try:
			s = self.stat()
			return s.f_bavail * s.f_bsize
		except OSError:
			return None
	
	def total(self):
		try:
			s = self.stat()
			return s.f_blocks * s.f_bsize
		except OSError:
			return None

	def mounted(self):
		# THANK YOU PYTHON FOR STRIPPING AWAY f_fsid.
		# TODO: can os.path.ismount be used?
		if self.force_mounted:
			return True
		procfile = tryOpen("/proc/mounts")
		for n in procfile.readlines():
			if n.split(' ')[1] == self.mountpoint:
				return True
		return False

DEVICEDB =  \
	{
		# dm8000:
		"/devices/platform/brcm-ehci.0/usb1/1-1/1-1.1/1-1.1:1.0": "Front USB Slot",
		"/devices/platform/brcm-ehci.0/usb1/1-1/1-1.2/1-1.2:1.0": "Back, upper USB Slot",
		"/devices/platform/brcm-ehci.0/usb1/1-1/1-1.3/1-1.3:1.0": "Back, lower USB Slot",
		"/devices/platform/brcm-ehci-1.1/usb2/2-1/2-1:1.0/host1/target1:0:0/1:0:0:0": "DVD Drive",
	}

class HarddiskManager:
	def __init__(self):
		self.hdd = [ ]
		self.cd = ""
		self.partitions = [ ]
		
		self.on_partition_list_change = CList()
		
		self.enumerateBlockDevices()
		
		# currently, this is just an enumeration of what's possible,
		# this probably has to be changed to support automount stuff.
		# still, if stuff is mounted into the correct mountpoints by
		# external tools, everything is fine (until somebody inserts 
		# a second usb stick.)
		p = [
					("/media/hdd", _("Harddisk")), 
					("/media/card", _("Card")), 
					("/media/cf", _("Compact Flash")),
					("/media/mmc1", _("MMC Card")),
					("/media/net", _("Network Mount")),
					("/media/ram", _("Ram Disk")),
					("/media/usb", _("USB Stick")),
					("/", _("Internal Flash"))
				]
		
		self.partitions.extend([ Partition(mountpoint = x[0], description = x[1]) for x in p ])

	def getBlockDevInfo(self, blockdev):
		devpath = "/sys/block/" + blockdev
		error = False
		removable = False
		blacklisted = False
		is_cdrom = False
		partitions = []
		try:
			removable = bool(int(open(devpath + "/removable").read()))
			dev = int(open(devpath + "/dev").read().split(':')[0])
#--->
#-			if dev in (7, 31): # loop, mtdblock
#---<
#+++>
			if dev in [1, 7, 31]: # ram, loop, mtdblock 
#+++<
				blacklisted = True
			if blockdev[0:2] == 'sr':
				is_cdrom = True
			if blockdev[0:2] == 'hd':
				try:
					media = open("/proc/ide/%s/media" % blockdev).read()
					if "cdrom" in media:
						is_cdrom = True
				except IOError:
					error = True
			# check for partitions
			if not is_cdrom:
				for partition in listdir(devpath):
					if partition[0:len(blockdev)] != blockdev:
						continue
					partitions.append(partition)
			else:
				self.cd = blockdev
		except IOError:
			error = True
		# check for medium
		medium_found = True
		try:
			open("/dev/" + blockdev).close()
		except IOError, err:
			if err.errno == 159: # no medium present
				medium_found = False
			
		return error, blacklisted, removable, is_cdrom, partitions, medium_found

	def enumerateBlockDevices(self):
		print "enumerating block devices..."
		for blockdev in listdir("/sys/block"):
			error, blacklisted, removable, is_cdrom, partitions, medium_found = self.getBlockDevInfo(blockdev)
			print "found block device '%s':" % blockdev, 
			if error:
				print "error querying properties"
			elif blacklisted:
				print "blacklisted"
			elif not medium_found:
				print "no medium"
			else:
				print "ok, removable=%s, cdrom=%s, partitions=%s, device=%s" % (removable, is_cdrom, partitions, blockdev)

				self.addHotplugPartition(blockdev)
				for part in partitions:
					self.addHotplugPartition(part)

	def getAutofsMountpoint(self, device):
		return "/autofs/%s/" % (device)

	def addHotplugPartition(self, device, physdev = None):
		if not physdev:
			dev, part = self.splitDeviceName(device)
			try:
				physdev = readlink("/sys/block/" + dev + "/device")[5:]
			except OSError:
				physdev = dev
				print "couldn't determine blockdev physdev for device", device

		# device is the device name, without /dev 
		# physdev is the physical device path, which we (might) use to determine the userfriendly name
		description = self.getUserfriendlyDeviceName(device, physdev)
		
		p = Partition(mountpoint = self.getAutofsMountpoint(device), description = description, force_mounted = True, device = device)
		self.partitions.append(p)
		self.on_partition_list_change("add", p)

		# see if this is a harddrive
		l = len(device)
		if l and not device[l-1].isdigit():
			error, blacklisted, removable, is_cdrom, partitions, medium_found = self.getBlockDevInfo(device)
			if not blacklisted and not removable and not is_cdrom and medium_found:
				self.hdd.append(Harddisk(device))
				self.hdd.sort()
				SystemInfo["Harddisk"] = len(self.hdd) > 0

	def removeHotplugPartition(self, device):
		mountpoint = self.getAutofsMountpoint(device)
		for x in self.partitions[:]:
			if x.mountpoint == mountpoint:
				self.partitions.remove(x)
				self.on_partition_list_change("remove", x)
		l = len(device)
		if l and not device[l-1].isdigit():
			for hdd in self.hdd:
				if hdd.device == device:
					hdd.stop()
					self.hdd.remove(hdd)
					break
			SystemInfo["Harddisk"] = len(self.hdd) > 0

	def HDDCount(self):
		return len(self.hdd)

	def HDDList(self):
		list = [ ]
		for hd in self.hdd:
			hdd = hd.model() + " - " + hd.bus()
			cap = hd.capacity()
			if cap != "":
				hdd += " (" + cap + ")"
			list.append((hdd, hd))
		return list

	def getCD(self):
		return self.cd

	def getMountedPartitions(self, onlyhotplug = False):
		parts = [x for x in self.partitions if (x.is_hotplug or not onlyhotplug) and x.mounted()]
		devs = set([x.device for x in parts])
		for devname in devs.copy():
			if not devname:
				continue
			dev, part = self.splitDeviceName(devname)
			if part and dev in devs: # if this is a partition and we still have the wholedisk, remove wholedisk
				devs.remove(dev)

		# return all devices which are not removed due to being a wholedisk when a partition exists
		return [x for x in parts if not x.device or x.device in devs]

	def splitDeviceName(self, devname):
		# this works for: sdaX, hdaX, sr0 (which is in fact dev="sr0", part=""). It doesn't work for other names like mtdblock3, but they are blacklisted anyway.
		dev = devname[:3]
		part = devname[3:]
		for p in part:
			if not p.isdigit():
				return devname, 0
		return dev, part and int(part) or 0

	def getUserfriendlyDeviceName(self, dev, phys):
		dev, part = self.splitDeviceName(dev)
		description = "External Storage %s" % dev
		try:
			description = open("/sys" + phys + "/model").read().strip()
		except IOError, s:
			print "couldn't read model: ", s
		for physdevprefix, pdescription in DEVICEDB.items():
			if phys.startswith(physdevprefix):
				description = pdescription

		# not wholedisk and not partition 1
		if part and part != 1:
			description += " (Partition %d)" % part
		return description

	def addMountedPartition(self, device, desc):
		already_mounted = False
		for x in self.partitions[:]:
			if x.mountpoint == device:
				already_mounted = True
		if not already_mounted:
			self.partitions.append(Partition(mountpoint = device, description = desc))
		
	def removeMountedPartition(self, mountpoint):
		for x in self.partitions[:]:
			if x.mountpoint == mountpoint:
				self.partitions.remove(x)
				self.on_partition_list_change("remove", x)

harddiskmanager = HarddiskManager()
