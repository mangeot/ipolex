<?php
// http://2bits.com/articles/installing-php-apc-gnulinux-centos-5.html
session_start();
$url = basename($_SERVER['SCRIPT_FILENAME']);

if(isset($_GET['progress_key'])) {
	$current = 0;
	$total = 1;
	if (ini_get('apc.rfc1867')) {
		$status = apc_fetch('upload_'.$_GET['progress_key']);
		$current = $status['current'];
		$total = $status['total'];
	}
	else if (ini_get('session.upload_progress.enabled')) {
		$progress_key = ini_get("session.upload_progress.prefix")."form1"; // File post form name
		$current = $_SESSION[$progress_key]["bytes_processed"];
		$total = $_SESSION[$progress_key]["content_length"];
	}
	else {
		echo 'PHP5.4 or APC';
	}
	echo $current/$total*100;
	die;
}
?>
<html>
 <head>
<script src="../js/jquery-1.4.0.js" type="text/javascript"></script>
<link href="../style/style_progress.css" rel="stylesheet" type="text/css" />
<script>
$(document).ready(function() { 
//

	setInterval(function() 
		{
	$.get("<?php echo $url; ?>?progress_key=<?php echo $_GET['up_id']; ?>&randval="+ Math.random(), { 
		//get request to the current URL (upload_frame.php) which calls the code at the top of the page.  It checks the file's progress based on the file id "progress_key=" and returns the value with the function below:
	},
		function(data)	//return information back from jQuery's get request
			{
				$('#progress_container').fadeIn(100);	//fade in progress bar	
				$('#progress_bar').width(data +"%");	//set width of progress bar based on the $status value (set at the top of this page)
				$('#progress_completed').html(parseInt(data) +"%");	//display the % completed within the progress bar
			}
		)},500);	//Interval is set at 500 milliseconds (the progress bar will refresh every .5 seconds)

});
</script>
</head>
<body style="margin:0px">
<!--Progress bar divs-->
<div id="progress_container">
	<div id="progress_bar">
  		 <div id="progress_completed"></div>
	</div>
</div>
</body>
</html>