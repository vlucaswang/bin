#!/usr/bin/env python
# -*- coding: utf-8 -*-
import   commands
import  xlsxwriter
sar = "sar -q -f sa22"
workbook = xlsxwriter.Workbook('ccccc.xlsx')
worksheet = workbook.add_worksheet()  #创建一个sheet
chart  =workbook.add_chart({'type':'line'})   #定义图标类型
# 获取 xls的数据
def  data(list_data):
    c=2 #计数器
    d= list_data[0]
    sar_date = commands.getstatusoutput(sar+str(d)+"|awk '{print $1}'")
    sar_date =sar_date[1].split('\n')
    del sar_date[0:2]
    for k in sar_date:
      worksheet.write('%s' % chr(97).upper()+str(c),k )
      c+=1
    a = 98 #用于英文字母
    for i  in list_data:
        i = str(i)
        sar_data = commands.getstatusoutput(sar+i+"|awk '{print $5}'")
        sar_data =sar_data[1].split('\n')
        del sar_data[0:3]
        #print sar_data
        sar_data = map(eval, sar_data)
        worksheet.write('%s' % chr(a).upper()+"1",int(i) )
        b=2  #计数器
        for h in sar_data:
            worksheet.write('%s' % chr(a).upper()+str(b),h)
            b+=1
        a+=1
#图标数据范围
def  chart_creat(column):
    #chart  =workbook.add_chart({'type':'line'})
    chart.add_series({
        'categories': '=Sheet1!$A$2:$A$145',
        'values':     '=Sheet1!$'+column+'$2:$'+column+'$146',
        #'line':      {'color':'red'},
        'name':'=Sheet1!$'+column+'$1',
    })
#循环图表数据 生成图表 定义格式
def  charrt(len_sar):
    for col  in  range(98,98+len_sar):
        chart_creat(chr(col).upper())
    chart.set_size({'width':1200,'height':289})
    chart.set_title({'name':'sar '})
    worksheet.insert_chart('F9',chart)
#取sar的日期  字符串最好
sar1 = ['10','11','12','09']
sar_len = len(sar1)
#执行函数
data(sar1)
charrt(sar_len)
workbook.close()