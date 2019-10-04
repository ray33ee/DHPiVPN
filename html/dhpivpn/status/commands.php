<html>
	<body>
		<?php
			//Make sure no other users are initiating commands
			if (shell_exec("cat /var/www/html/dhpivpn/status/lock") == "off\n")
			{
				//Turn the lock on to prevent other commands
				shell_exec("sudo sh -c \"echo 'on' > /var/www/html/dhpivpn/status/lock\"");

				//List of accepted daemon processesa
				$daemon_list = array('openvpn@server', 'openvpn@outgoing', 'pihole-FTL', 'transmission-daemon', 'apache2', 'smbd', 'noip2');
				
				//List of accepted service commands
				$command_list = array('start', 'stop', 'restart');
				
				//Get formatted daemon and command
				$daemon = htmlspecialchars($_GET["daemon"]);
				$command = htmlspecialchars($_GET["command"]);

				echo "<p id=\"daemon\">Daemon: '".htmlspecialchars($daemon)."'.</p>";
				echo "<p id=\"command\">Command: '".htmlspecialchars($command)."'.</p>";

				//Check validity of daemon and command
				if (in_array($daemon, $daemon_list) && in_array($command, $command_list))
				{
					shell_exec("sudo sh -c \"uptime | awk '{print $1 }' >> /home/pi/debug.txt\"");

					//Execute command
					shell_exec("sudo service ".$daemon." ".$command);

					//Get status of daemon
					$status = shell_exec("service ".$daemon." status | awk '/Active:/ { if (!match($0, \"awk\")) {printf(\"%s\", $2); } }'");

					echo "<p id=\"status\">Status: '".$status."'.</p>";
					
					//If the status matches the chosen command, success
					if ($status == "active" && ($command == "start" || $command == "restart") || ($status == "inactive" && $command == "stop"))
					{
						echo "<p id=\"result\">Success</p>";
					}
					else
					{
						echo "<p id=\"result\">Status does not match command</p>";
					}
				}
				else
				{
					echo "<p id=\"result\">Invalid command or daemon</p>";
				}

				//Turn the lock off to reenable commands
				shell_exec("sudo sh -c \"echo 'off' > /var/www/html/dhpivpn/status/lock\"");
			}
			else
			{
				echo "<p id=\"result\">Locked</p>";
			}
		?>
	</body>
</html>
