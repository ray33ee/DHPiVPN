<!DOCTYPE html>

<html>

	<head>

		<script src="/dhpivpn/scripts/main.js"></script>

		<style>

			.col 
			{
			  	float: left;
			}

			.clearfix::after {
			  content: "";
			  clear: both;
			  display: table;
			}

			.row
			{
				padding-bottom: 20px;
			}

			.inner
			{
			  	margin: 10px;
			  	padding-left: 20px;
			  	padding-right: 20px;
				padding-top: 5px;
				padding-bottom: 5px;
				color: white;
				width: 20%;
				height: 20%;
			}

			.status
			{
			  	margin: 5px;
				color: black;
				width: 15%;
				height: 20%;
			}

			.indicator
			{
				margin: 2px;
			}

			.bg-green
			{
				background-image: linear-gradient(to bottom, #00B446, #45C600);
			}

			.bg-red
			{
				background-image: linear-gradient(to bottom, #FF0000, #FF3E00);
			}

			.bg-orange
			{
				background-image: linear-gradient(to bottom, #DB9F00, #FFD30F);
			}

			.bg-purple
			{
				background-image: linear-gradient(to bottom, #6400FF, #8F00FF);
			}


		</style>


		<?php
		
			function getDaemonList()
			{
				return array('openvpn@server', 'openvpn@outgoing', 'pihole-FTL', 'transmission-daemon', 'apache2', 'smbd', 'noip2');
			}

			function getLabels()
			{
				return array('Inbound', 'Outbound', 'PiHole', 'Transmission', 'Web Server', 'Samba', 'NoIp');
			}

		?>

	</head>


	<body onload="start_status()">

		<script>
			//var locked = false;
		
			function start_status()
			{
				var delayInMilliseconds = 2000; //2 seconds
				setInterval(function() { getData_status(); }, delayInMilliseconds);
			}

			function getData_status()
			{
				var xhttp = new XMLHttpRequest();
				xhttp.onreadystatechange = function()
				{
					if (this.readyState == 4 && this.status === 200)
					{
						var domparser = new DOMParser();

						doc = domparser.parseFromString(this.responseText, "text/html");
						
						daemonList.forEach(function (item, index)
						{
							document.getElementById(item + "_status").innerHTML = getFormattedActivity(doc.getElementById(item + "_status").innerHTML);
							document.getElementById(item + "_status").style.color = getColor(doc.getElementById(item + "_status").innerHTML);

							document.getElementById(item + "_pid").innerHTML = doc.getElementById(item + "_pid").innerHTML;
							document.getElementById(item + "_memory").innerHTML = doc.getElementById(item + "_memv").innerHTML;
						});
						
						
					}			
				}
				xhttp.open("GET", "/dhpivpn", true);
				xhttp.send();
			}

			function command(daemon, command)
			{
				var xhttp = new XMLHttpRequest();
				xhttp.onreadystatechange = function()
				{
					var domparser = new DOMParser();
					var doc = domparser.parseFromString(this.responseText, "text/html");

					//var result = doc.getElementById("result").innerHTML;

				};
				xhttp.open("GET", "/dhpivpn/status/commands.php?daemon=" + daemon + "&command=" + command, true);
				xhttp.send();
			}
			

		</script>

		<div id="title">Title</div>

		<div class="" style="display: flex">
			<div class="" style="width: 10%">
				<ul>
					<li><a href="/">Home</a></li>
					<li><a href="/dhpivpn/status/">Status</a></li>
					<li><a href="/dhpivpn/speed/">Speed</a></li>
					<li><a href="/dhpivpn/admin/">Admin</a></li>
					<li><a href="/admin">PiHole</a></li>
					<li><a href="http://dhpivpn.io:9091/transmission">Transmission</a></li>
				</ul>
			</div>
			

			<div class="" style="width: 90%">
				<?php 
					
					$labels = getLabels();
					$count  = 0;

					foreach (getDaemonList() as $val)
					{
						echo "<div class=\"row clearfix\">";
						echo "	<div class=\"col status\">";
						echo "		<div class=\"col\"><h3>".$labels[$count].": </h3></div>";
						echo "		<div class=\"col indicator\"><h3 id=\"".$val."_status\">-</h3></div>";
						echo "	</div>";
						echo "	<div class=\"col status\">";
						echo "		<div class=\"col\"><h5>PID: </h5></div>";
						echo "		<div class=\"col indicator\"><h5 id=\"".$val."_pid\">-</h5></div>";
						echo "	</div>";
						echo "	<div class=\"col status\">";
						echo "		<div class=\"col\"><h5>Memory: </h5></div>";
						echo "		<div class=\"col indicator\"><h5 id=\"".$val."_memory\">-</h5></div>";
						echo "	</div>";
						echo "	<div class=\"col status\">";
						echo "		<div class=\"col\" style=\"padding-right: 5px\"><h5 onclick=\"command('".$val."', 'start')\">start</h5></div>";
						echo "		<div class=\"col\" style=\"padding-right: 5px\"><h5 onclick=\"command('".$val."', 'stop')\">stop</h5></div>";
						echo "		<div class=\"col\" style=\"padding-right: 5px\"><h5 onclick=\"command('".$val."', 'restart')\">restart</h5></div>";
						echo "	</div>";
						echo "</div>";
						
						$count++;
					}
					
				?>

			</div>
			
			<p id="debug"> </p>

		</div>

	</body>
</html>
