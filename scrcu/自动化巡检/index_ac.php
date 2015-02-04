<html>
<head>
<META http-equiv="Content-Type" content="text/html; charset=gb2312">
<META name=description" content="系统保障部内部网站">
<title>rccb x86 Linux 巡检报告单</title>
<link href="style.css" rel="stylesheet" type="text/css">

</head>
<body>
<table id="1" border="0" cellpadding="0" cellspacing="0">
<tr><td><img src="logo.gif" width="382" height="120" alt="rccb logo" /></td><td> <H1> X86 平台巡检报告 </H1></td></tr>
</table>


<?PHP
date_default_timezone_set("Asia/Chongqing");
$today=date("Ymd");
$yesterday=date("Ymd", strtotime("-1 days"));
$file_path="tmphost6";

$machine_ori_no=count(file($file_path));
$machine_act_no=count(scandir($today))-2;

$yesterdayfiles=array_map('basename',glob("$yesterday/*.txt",GLOB_BRACE));
$todayfiles=array_map('basename',glob("$today/*.txt",GLOB_BRACE));
$missingfiles["yesterdayfiles"]=array_diff($todayfiles,$yesterdayfiles);
$missingfiles["todayfiles"]=array_diff($yesterdayfiles,$todayfiles);
#print_r($missingfiles);


echo "<br>应巡检机器 $machine_ori_no 台,实际巡检机器 $machine_act_no 台.";
foreach($missingfiles["todayfiles"] as $x=>$x_value) {
  $x_value_hostname=explode("_","$x_value");
  echo "今日误差机器为" . $x_value_hostname[0] . " ,IP为" . $x_value_hostname[1];
#  echo "<br>";
}
echo "<br>巡检报告生成时间: <B>$today</B>";
echo "<br>友情链接：<a href='http://10.128.128.129/report/'>Power平台巡检报告</a>";
echo '<table border="1" cellpadding="1" cellspacing="0">';
echo "<tr><td>主机名</td><td>IP地址</td><td>应用名称</td><td>管理员</td><td>硬件错误</td><td>软件错误</td><td>系统错误</td><td>中间件错误</td><td>数据库错误</td></tr>";
if ($handle = opendir("$today")) {
  while (false !== ($file = readdir($handle))) {
  $dir[]=$file;
  }
  closedir($handle);
  asort($dir);
  foreach ($dir as $name) {
    if ($name != "." && $name != ".." && $name != "Logs") {
      $hostname=explode("_","$name");
      echo "<tr><td><a href='$today/$name'>$hostname[0]</a><br></td>";
      echo "<td>$hostname[1]</td>";
      $filecontents=explode("\n",file_get_contents("$today/".$name));
      $laststr=$filecontents[count($filecontents)-2];
      $hello = explode(',',$laststr); 

      for($index=0;$index<count($hello);$index++){ 
	if ($hello[$index]!=0) {
        echo "<td bgcolor=red>&nbsp $hello[$index] &nbsp</td>";
	} else {
        echo "<td>&nbsp$hello[$index]&nbsp</td>";
	}
      }
    }
    echo "</tr>";
  }
}
echo "</table>";
echo "<br>友情链接：<a href='http://10.128.128.129/report/'>Power平台巡检报告</a>";

?>
</body>

