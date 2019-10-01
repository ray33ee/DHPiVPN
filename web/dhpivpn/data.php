<!DOCTYPE html>

<?php

	function getDaemonList()
	{
		return array('openvpn@server', 'openvpn@outgoing', 'pihole-FTL', 'transmission-daemon', 'apache2', 'smbd', 'noip2');
	}

	function externalIP()
	{
		return shell_exec("dig TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F\"\\\"\" '{print $2}'");
	}

	function memPercentage()
	{
		$TotalMem = shell_exec("free -k | awk '/Mem:/ {print $2}'");
		$UsedMem = shell_exec("free -k | awk '/Mem:/ {print $3}'");
		return round($UsedMem / $TotalMem * 100, 2);
	}

	function CPULoad()
	{
		return chop(shell_exec("uptime | awk '{ind = index($0, \"load average:\"); if (ind != 0) { print substr($0, ind + 14); } else { printf(\"-\");  } }'"));
	}

	function Bandwidth()
	{
		return shell_exec("vnstat -tr 2 | awk '/tx/ {printf(\"<p id=\\\"tx\\\">%s%s<p>\", $2, $3)} /rx/ {printf(\"<p id=\\\"rx\\\">%s%s<p>\", $2, $3)}' ");
	}

	function whatsInstalled()
	{
		$Flags = 0;
		$Flags |= shell_exec("ls /usr/sbin -l | awk 'BEGIN {flags = 0;} /openvpn/ { flags = or(flags, 1); } /apache2/ { flags = or(flags, 8); } /smbd/ { flags = or(flags, 16); }  END {print flags}'");
		$Flags |= shell_exec("ls /usr/bin -l | awk 'BEGIN {flags = 0;} /transmission-daemon/ { flags = or(flags, 4); } /pihole-FTL/ { flags = or(flags, 2); }  END {print flags}'");
		$Flags |= shell_exec("ls /usr/local/bin -l | awk 'BEGIN {flags = 0;} /noip2/ { flags = or(flags, 32); } END {print flags}'");
		return $Flags;
	}

	function getStatus($daemon)
	{
		return shell_exec("service ".$daemon." status | awk '/Active:/ { if (!match($0, \"awk\")) {printf(\"%s\", $2); } }'");
	}

	function getVPNName()
	{
		return shell_exec("awk '/verify-x509-name/ {print substr($2, 1, 7)}' /etc/openvpn/outgoing.conf");
	}

	function getPID($name)
	{
		if ($name == "pihole-FTL") //If the process is pihole, find the pid via pidof
		{
			return shell_exec("pidof pihole-FTL");
		}
		else //For the other daemons, use service
		{
			return shell_exec("service ".$name." status | awk '/Main PID:/ { if (!match($0, \"awk\")) {printf(\"%s\", $3); }}'");
		}
	}

	function getCPUTime($p_id)
	{
		return shell_exec("cat /proc/".$p_id."/stat | awk '{printf(\"%i\", $14 + $15 + $16 + $17);}'");
	}

	function getCPUElapsed()
	{
		return shell_exec("cat /proc/stat | head -1 | awk '{printf(\"%i\", $1+$2+$3+$4+$5+$6+$7+$8+$9+$10)}'");
	}

	function getMemory($p_id)
	{
		return shell_exec("ps h -q ".$p_id." -eo %mem | awk '{printf(\"%s\", $1); }'");
	}

?>

System:
<p id="mp"><?php $Percentage = memPercentage(); echo $Percentage; ?></p>
<p id="cpul"><?php $Load = CPULoad(); echo $Load; ?></p>
Outbound VPN:
<p id="vpn"><?php $VPN = getVPNName(); echo $VPN; ?></p>
<p id="eip"><?php $ExternalIP = externalIP(); echo $ExternalIP; ?></p>
Daemons:
<p id="bin"><?php $Installed = whatsInstalled(); echo $Installed; ?></p>
Bandwidth:
<?php echo Bandwidth(); ?>

Snapshot:
<div id="snap">
	<?php
		$daemons = getDaemonList();
		foreach ($daemons as $val)
		{
			echo "<div id=\"".$val."\">";
			$pid = getPID($val);
			echo "<p id=\"${val}_pid\">$pid</p>";
			echo "<p id=\"${val}_mem\">".getMemory($pid)."</p>";
			echo "<p id=\"${val}_cpu\">".getCPUTime($pid)."</p>";
			echo "<p id=\"${val}_status\">".getStatus($val)."</p>";
			echo "</div>";
		}
		echo "<p id=\"cpu_elapsed\">".getCPUElapsed()."</p>";
	?>
	
</div>


</body>
</html>












