<img src="logo.gif" width="382" height="120" alt="" />

<?PHP

date_default_timezone_set("Asia/Chongqing");
$today=date("Ymd");
$yesterday=date("Ymd", strtotime("-1 days"));
$file_path="tmphost6";

$machine_ori_no=count(file($file_path));
$machine_act_no=count(scandir($today))-3;

$yesterdayfiles=array_map('basename',glob("$yesterday/*.txt",GLOB_BRACE));
$todayfiles=array_map('basename',glob("$today/*.txt",GLOB_BRACE));
$missingfiles["yesterdayfiles"]=array_diff($todayfiles,$yesterdayfiles);
$missingfiles["todayfiles"]=array_diff($yesterdayfiles,$todayfiles);
#print_r($missingfiles);

echo "<br>应巡检机器 $machine_ori_no 台,实际巡检机器 $machine_act_no 台,";
foreach($missingfiles["todayfiles"] as $x=>$x_value) {
  $x_value_hostname=explode("_","$x_value");
  echo "今日误差机器为" . $x_value_hostname[0] . " ,IP为" . $x_value_hostname[1];
}
echo "<br>巡检报告生成时间: $today";
echo "<br>以下参数中,0表示没问题,1表示有问题.";
echo "<br><a href='$today/all.txt'>总表下载</a>";
echo "<table width=\"500\" border=\"2\">";
echo "<tr><td>主机名</td><td>IP地址</td><td>应用名称</td><td>NTP当前主服务器</td><td>时差</td><td>NTPD是否运行</td><td>NTPD自动启动</td><td>NTP配置正确</td><td>CRONTAB运行NTPDATE</td><td>VMware校时</td><td>时区</td><td>问题个数</td></tr>";
if ($handle = opendir("$today")) {
  while (false !== ($file = readdir($handle))) {
  $dir[]=$file;
  }
  closedir($handle);
  asort($dir);
  foreach ($dir as $name) {
    if ($name != "." && $name != ".." && $name != "all.txt") {
      $hostname=explode("_","$name");
      echo "<tr><td><a href='$today/$name'>$hostname[0]</a><br></td>";
      echo "<td>$hostname[1]</td>";
      $laststr=file_get_contents("$today/".$name);
      $hello=explode(',',$laststr); 

      for($index=1;$index<count($hello);$index++){ 
        echo "<td>&nbsp$hello[$index]&nbsp</td>";
      }
    }
    echo "</tr>";
  }
}
echo "</table>";


?>
