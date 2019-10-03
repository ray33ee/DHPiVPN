<html>
	<body>
		<?php
			//List of accepted daemon processesa
			$daemon_list = array('openvpn@server', 'openvpn@outgoing', 'pihole-FTL', 'transmission-daemon', 'apache2', 'smbd', 'noip2');
			
			//List of accepted service commands
			$command_list = array('start', 'stop', 'restart');
			
			//Get formatted daemon and command
			$daemon = htmlspecialchars($_GET["daemon"]);
			$command = htmlspecialchars($_GET["command"]);

			echo "<p>Daemon: '".htmlspecialchars($daemon)."'.</p>";
			echo "<p>Command: '".htmlspecialchars($command)."'.</p>";

			//Check validity of daemon and command
			if (in_array($daemon, $daemon_list) && in_array($command, $command_list))
			{
				//Execute command
				shell_exec("sudo service ".$daemon." ".$command);

				//Get status of daemon
				$status = shell_exec("service ".$daemon." status | awk '/Active:/ { if (!match($0, \"awk\")) {printf(\"%s\", $2); } }'");

				echo "<p>Status: '".$status."'.</p>";
				
				//If the status matches the chosen command, success
				if ($status == "active" && ($command == "start" || $command == "restart") || ($status == "inactive" && $command == "stop"))
				{
					echo "<p id=\"status\">Success</p>";
				}
				else
				{
					echo "<p id=\"status\">Status does not match command</p>";
				}
			}
			else
			{
				echo "<p id=\"status\">Invalid command or daemon</p>";
			}
		?>
	</body>
</html>
