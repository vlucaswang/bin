<img src="logo.gif" width="382" height="120" alt="" />

<?PHP
date_default_timezone_set("Asia/Chongqing");
$today=date("Ymd");
$file_path="tmphost6";

$machine_ori_no=count(file($file_path));
$machine_act_no=count(scandir($today))-2;

echo "<br>应巡检机器 $machine_ori_no 台,实际巡检机器 $machine_act_no 台,巡检报告生成时间: $today</br>";
echo "<p><a href='http://10.128.128.129/report/'>Power平台巡检报告</a></p>";
echo "<table border=\"1\">";
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
//    echo "<tr><td>$hostname[0]</td>";
      echo "<tr><td><a href='$today/$name'>$hostname[0]</a><br></td>";
      echo "<td>$hostname[1]</td>";
      $filecontents=explode("\n",file_get_contents("$today/".$name));
//    var_dump($filecontents);
      $laststr=$filecontents[count($filecontents)-2];
//    echo "<td>$laststr</td></tr>";
      $hello = explode(',',$laststr); 

      for($index=0;$index<count($hello);$index++){ 
//      echo "<td>$hello[$index]</td>";}
        echo "<td>&nbsp$hello[$index]&nbsp</td>";
      }
    }
    echo "</tr>";
  }
}
echo "</table>";
?>
