<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
		"http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<title>Welcome to Mediabox</title>
<style type="text/css">
body {
  font-family: "Open Sans", sans-serif;
  background-color: lightblue;
}
</style>
<h1>Welcome to Mediabox!</h1>
<h3><u>Basic Information & Configuration</u></h3>
<b><u>Notes:</u></b><br />
<ul>
<li>Radarr and Couchpotato do the same thing = Movie Management</li>
</ul>
-- Generally you will only want to choose/use one of each.<br />
<ul>
<li>The <b>Minio</b> login is: minio / minio123.</li>
</ul>
<h3>Mediabox Container Management</h3>
<b><u>Portainer:</u></b><br />
To help you manage your Mediabox Docker containers Portainer is available.<br />
Portainer is a Docker Management UI to help you work with the containers etc.<br />
A password will need to be set for the <b>admin</b> account upon initial login.<br />
<br />
<h3><u>Manual Configuration steps:</u></h3>  
<b><u>Radarr:</u></b><br />
<ul>
<li>Click on the Settings icon<br />
<li>Click on the Download Client Tab<br />
<li>Click on the + sign to add a download client<br />
<li>Under the "Torrent" section Select Deluge<br />
<li>Enter these settings:<br />
    * Name: Deluge<br />
    * Enable: Yes<br />
    * Host: locip<br />
    * Port: 8112<br />
    * Password: deluge (unless you have changed it)<br />
    * Category: blank<br />
    * Use SSL: No<br />
<li>Optional: Click on the media management tab and configure the renamer<br />
</ul>
<br />
<b><u>Sonarr & Lidarr</u></b><br />
<ul>
<li>Same instructions as Radarr<br />
</ul>
<br />
<b><u>PLEX:</u></b><br />
When adding libraries to PLEX use these settings:<br />
<ul>
<li>Movies = /data/movies<br />
<li>Music = /data/music<br />
<li>TV = /data/tvshows<br />
</ul>
<br />
<b><u>NBZGet:</u></b><br />
<ul>
<li>Username: daemonun<br />
<li>Password: daemonpass<br />
</ul>
<h3>Container Updates</h3>
<b><u>Watchtower:</u></b><br />
The Watchtower container monitors the all of the Mediabox containers and if there is an update to any container's base image it updates the container.<br />
Watchtower will detect the change, download the new image, gracefully stop the container(s), and re-launch them with the new image.<br />
<h1>Troubleshooting</h1>
If you are having issues with Mediabox or any of your continers please take look at the settings being used.<br />
Below are the variables in your .env file: (<b>NOTE</b>: For your security PIA credentials are no longer shown here.)
<pre>
<?php
echo file_get_contents("./env.txt");
?>
</pre>
</body>
</html>
