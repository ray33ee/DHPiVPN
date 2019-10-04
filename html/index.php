<!DOCTYPE html>

<html>

	<head>

		<script src="https://cdn.jsdelivr.net/npm/chart.js@2.8.0"></script>
		<script src="dhpivpn/scripts/main.js"></script>

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


	<body onload="start_home()">

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
				<div class="row clearfix">
					<div class="col inner bg-green">
						<h5 align="center">Connections</h5>
						<h1 id="inbound_status" title="Inbound server status">-</h1>
						<h3 id="outbound_status" title="Outbound server status">-</h3>
					</div>
					<div class="col inner bg-orange">
						<h5 align="center">Outbound VPN</h5>
						<h1 id="vpn_server" title="Outbound VPN server name">-</h1>
						<h3 id="ip_address" title="External IP of Pi">-</h3>
					</div>
					<div class="col inner bg-purple">
						<h5 align="center">Bandwidth</h5>
						<h1 id="tx_speed" title="Transmit speed from eth0">TX: -</h1>
						<h3 id="rx_speed" title="Receive speed from eth0">RX: -</h3>
					</div>
					<div class="col inner bg-red">
						<h5 align="center">CPU</h5>
						<h1 id="cpu_load" title="CPU Load">-</h1>
						<h3 id="memory_usage" title="Total memory usage">-</h3>
					</div>
				</div>

				<div class="row clearfix">

					<?php
						$labels = getLabels();
						$count  = 0;

						foreach (getDaemonList() as $val)
						{
							echo "<div id=\"".$val."_box\" class=\"col status\">";
							echo "<div class=\"col\"><h3>".$labels[$count].": </h3></div>";
							echo "<div class=\"col indicator\"><h3 id=\"".$val."_circle\">●</h3></div>";
							echo "</div>";
							$count++;
						}
					?>

				</div>

				<div class="row clearfix">
					<div class="col" style="margin-right: 100px"> 
						<canvas id="cpu_chart" style="display: block;" height="300px" width="450px"></canvas>
					</div>
					<div class="col" style="margin-right: 100px"> 
						<canvas id="mem_chart" style="display: block;" height="300px" width="450px"></canvas>
					</div>
				</div>

				<div id="debug" class="row clearfix">
					clearer gradient on yellow and green. Bigger adjustment on the yellow. Sum up CPU and Memory free and idle and show in charts
				</div>
			</div>
		</div>

	</body>
</html>
