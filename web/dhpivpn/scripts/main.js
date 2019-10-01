var chart_colours = [
					'rgba(255, 99, 132, 1)',
					'rgba(54, 162, 235, 1)',
					'rgba(255, 206, 86, 1)',
					'rgba(75, 192, 192, 1)',
					'rgba(153, 102, 255, 1)',
					'rgba(153, 2, 255, 1)',
					'rgba(255, 159, 64, 1)',
					'rgba(200, 200, 200, 1)'
				];

var daemonList = ['openvpn@server', 'openvpn@outgoing', 'pihole-FTL', 'transmission-daemon', 'apache2', 'smbd', 'noip2'];

var labels = ['Incoming', 'Outgoing', 'PiHole', 'Transmission', 'Web Server', 'Samba', 'NoIp'];

var cpu_data = [0,0,0,0,0,0,0,100];
var mem_data = [0,0,0,0,0,0,0,100];

var cpuChart;
var memChart;

var doc;
var prevDoc;

function start()
{
	//Setup charts
	cpuChart = new Chart(document.getElementById('cpu_chart').getContext('2d'), {
		options: { legend: {position: 'left'}},
		type: 'doughnut',
		data: {
			labels: labels.concat(['Idle']),
			datasets: [{
				data: cpu_data,
				backgroundColor: chart_colours,
				borderWidth: 1
			}]
		}
	});
	memChart = new Chart(document.getElementById('mem_chart').getContext('2d'), {
		options: { legend: {position: 'left'}},
		type: 'doughnut',
		data: {
			labels: labels.concat(['Free']),
			datasets: [{
				data: mem_data,
				backgroundColor: chart_colours,
				borderWidth: 1
			}]
		}
	});

	// Call startup script
	startupCall();

	// Get initial snapshot
	var xhttp = new XMLHttpRequest();
	xhttp.open("GET", "dhpivpn/startup.php", true);
	xhttp.send();

	//
	xhttp.onreadystatechange = function()
	{
		var domparser = new DOMParser();
		prevDoc = domparser.parseFromString(this.responseText, "text/html");
	};

	// Start main loop
	var delayInMilliseconds = 2000; //2 seconds
	setInterval(function() { getData(); }, delayInMilliseconds);
}

function getColor($status)
{
	if ($status == "")
		return "grey";
	if ($status == "active")
		return "green";
	if ($status == "inactive")
		return "orange";
	if ($status == "failed")
		return "red";
}

function getFormattedStatus($Status)
{
	return $Status == "" ? "-" : $Status
}

function startupCall()
{
	var xhttp = new XMLHttpRequest();
	xhttp.open("GET", "dhpivpn/startup.php", true);
	xhttp.send();
}

function getCPUUsage(service)
{
	return (doc.getElementById(service + "_cpu").innerHTML - 
prevDoc.getElementById(service + "_cpu").innerHTML) 
  / (doc.getElementById("cpu_elapsed").innerHTML -prevDoc.getElementById("cpu_elapsed").innerHTML);
}

function getData()
{
	var xhttp = new XMLHttpRequest();
	xhttp.onreadystatechange = function()
	{
		if (this.readyState == 4 && this.status === 200)
		{
			var domparser = new DOMParser();
			var memTotal = 0;
			doc = domparser.parseFromString(this.responseText, "text/html");
			document.getElementById("vpn_server").innerHTML =  getFormattedStatus(doc.getElementById("vpn").innerHTML);
			document.getElementById("ip_address").innerHTML = doc.getElementById("eip").innerHTML;
			document.getElementById("cpu_load").innerHTML = doc.getElementById("cpul").innerHTML;
			document.getElementById("tx_speed").innerHTML = "TX: " + doc.getElementById("tx").innerHTML;
			document.getElementById("rx_speed").innerHTML = "RX: " + doc.getElementById("rx").innerHTML;
			document.getElementById("memory_usage").innerHTML = doc.getElementById("mp").innerHTML + "%";
			
			// Get a set of flags, indicating which software is installed
			var installed = doc.getElementById("bin").innerHTML;
			
			if (installed & 1 == 1)
			{
				document.getElementById("inbound_status").innerHTML = doc.getElementById("in").innerHTML
				document.getElementById("outbound_status").innerHTML = doc.getElementById("out").innerHTML;
			}
			else				
			{
				document.getElementById("inbound_status").innerHTML = "missing";
				document.getElementById("outbound_status").innerHTML = "missing";
			}

			document.getElementById("debug").innerHTML = prevDoc.body.innerHTML;
	
			daemonList.forEach(function (item, index)
			{
				document.getElementById(item + "_circle").style.color = getColor(doc.getElementById(item + "_status").innerHTML);
				document.getElementById(item + "_box").title = labels[index] + ": " + getFormattedStatus(doc.getElementById(item + "_status").innerHTML);
				//cpu_data[index] = getCPUUsage(item);
				mem_data[index] = doc.getElementById(item + "_mem").innerHTML;
				memTotal += mem_data[index];
			});

			mem_data[mem_data.length - 1] = 100 - memTotal;

			cpuChart.Data = cpu_data;
			memChart.Data = mem_data;
			
			cpuChart.update();
			memChart.update();

			prevDoc = doc;
			
		}			
	}
	xhttp.open("GET", "dhpivpn/data.php", true);
	xhttp.send();
}
