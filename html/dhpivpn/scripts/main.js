var chart_colours = [
					'rgba(255, 99, 132, 1)',
					'rgba(54, 162, 235, 1)',
					'rgba(255, 206, 86, 1)',
					'rgba(75, 192, 192, 1)',
					'rgba(124, 204, 0, 1)',
					'rgba(153, 102, 255, 1)',
					'rgba(255, 159, 64, 1)',
					'rgba(200, 200, 200, 1)'
				];

var daemonList = ['openvpn@server', 'openvpn@outgoing', 'pihole-FTL', 'transmission-daemon', 'apache2', 'smbd', 'noip2'];

var labels = ['Incoming', 'Outgoing', 'PiHole', 'Transmission', 'Web Server', 'Samba', 'NoIp'];

var cpu_data = [0,0,0,0,0,0,0,1];
var mem_data = [0,0,0,0,0,0,0,1];

var cpuChart;
var memChart;

var doc;
var prevDoc;

function round(value, precision)
{
	return Number(Math.round(value+'e'+precision)+'e-'+precision);
}

function start()
{
	//Setup charts
	cpuChart = new Chart(document.getElementById('cpu_chart').getContext('2d'), {
		options: { legend: {position: 'left'}},
		type: 'doughnut',
		data: {
			labels: labels.concat(['Other']),
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
			labels: labels.concat(['Other']),
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
	xhttp.onreadystatechange = function()
	{
		var domparser = new DOMParser();
		prevDoc = domparser.parseFromString(this.responseText, "text/html");
	};
	xhttp.open("GET", "dhpivpn/data.php", true);
	xhttp.send();

	//
	

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

function getCPUElapsed()
{
	return doc.getElementById("cpu_elapsed").innerHTML - prevDoc.getElementById("cpu_elapsed").innerHTML;
}

function getCPUUsage(service)
{
	var percentage = round((doc.getElementById(service + "_cpu").innerHTML - 
prevDoc.getElementById(service + "_cpu").innerHTML) 
  / getCPUElapsed() * 100.0, 2);

	return (percentage < 0 || percentage > 100) ? 0 : percentage; //To protect against overflow
}

function getTimeElapsed()
{
	var MagicConstantThatIsActuallyTicksPerSeconfOfProcessor = 100 // see sysconf(_SC_CLK_TCK) and http://man7.org/linux/man-pages/man5/proc.5.html

	return getCPUElapsed() / MagicConstantThatIsActuallyTicksPerSeconfOfProcessor;
}

function getBandwidth(direction)
{
	var rate = (doc.getElementsByTagName(direction)[0].innerHTML - prevDoc.getElementsByTagName(direction)[0].innerHTML) / getTimeElapsed();
	var units = "KB/s";
	if (rate < 0)
		return "-";
	if (rate > 1000)
	{
		rate = rate / 1024.0;
		units = "MB/s"
		if (rate > 1000)
		{
			rate = rate / 1024.0;
			units = "GB/s"
		}
	}
	return round(rate, 2) + " " + units;
}

function getData()
{
	var xhttp = new XMLHttpRequest();
	xhttp.onreadystatechange = function()
	{
		if (this.readyState == 4 && this.status === 200)
		{
			var domparser = new DOMParser();
			var memTotal = 0.0;
			var cpuTotal = 0.0;
			var cpuLegend = ['', '', '', '', '', '', ''];
			var memLegend = ['', '', '', '', '', '', ''];	

			doc = domparser.parseFromString(this.responseText, "text/html");
			document.getElementById("vpn_server").innerHTML =  getFormattedStatus(doc.getElementById("vpn").innerHTML);
			document.getElementById("ip_address").innerHTML = doc.getElementById("eip").innerHTML;
			document.getElementById("cpu_load").innerHTML = doc.getElementById("cpul").innerHTML;
			document.getElementById("tx_speed").innerHTML = "TX: " + getBandwidth("tx");
			document.getElementById("rx_speed").innerHTML = "RX: " + getBandwidth("rx");
			document.getElementById("memory_usage").innerHTML = doc.getElementById("mp").innerHTML + "%";
			
			// Get a set of flags, indicating which software is installed
			var installed = doc.getElementById("bin").innerHTML;
			
			if (installed & 1 == 1)
			{
				document.getElementById("inbound_status").innerHTML = doc.getElementById("openvpn@server_status").innerHTML
				document.getElementById("outbound_status").innerHTML = doc.getElementById("openvpn@outgoing_status").innerHTML;
			}
			else				
			{
				document.getElementById("inbound_status").innerHTML = "missing";
				document.getElementById("outbound_status").innerHTML = "missing";
			}
	
			daemonList.forEach(function (item, index)
			{
				//Set the status values of all daemons
				document.getElementById(item + "_circle").style.color = getColor(doc.getElementById(item + "_status").innerHTML);
				document.getElementById(item + "_box").title = labels[index] + ": " + getFormattedStatus(doc.getElementById(item + "_status").innerHTML);
				
				//Get the memory and cpu usages of all daemons and sum up 'other' section
				memTotal += mem_data[index] = Number(doc.getElementById(item + "_mem").innerHTML);
				cpuTotal += cpu_data[index] = getCPUUsage(item);

				//Add entries and percentages to legend
				cpuLegend[index] = labels[index] + ": " + cpu_data[index] + "%";
				memLegend[index] = labels[index] + ": " + mem_data[index] + "%";
			});

			//Calculate 'other' (idle for cpu or free for mem) 
			mem_data[mem_data.length - 1] = round(100.0 - memTotal, 2);
			cpu_data[cpu_data.length - 1] = round(100.0 - cpuTotal, 2);

			//Add 'other' to legend
			cpuLegend[labels.length] = "Other: " + cpu_data[cpu_data.length - 1] + "%";
			memLegend[labels.length] = "Other: " + mem_data[mem_data.length - 1] + "%";


			//Add legends to chart
			cpuChart.data.labels = cpuLegend;
			memChart.data.labels = memLegend;

			//Add data to chart
			cpuChart.Data = cpu_data;
			memChart.Data = mem_data;
			
			//Update charts
			cpuChart.update();
			memChart.update();

			//
			prevDoc = doc;
			
		}			
	}
	xhttp.open("GET", "dhpivpn/data.php", true);
	xhttp.send();
}
