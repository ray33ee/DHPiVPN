<!DOCTYPE html>

<html>

	<head>

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
					change dhpivpn, transmisison and pihole passwords
				</div>

			</div>
		</div>

	</body>
</html>
