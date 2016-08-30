# MFPerformanceMonitor
A tool to monitor ios app performance such as memory and cpu.

特点：

*	监控单个ViewController所占用的内存（ViewDidLoad - Alloc）以及销毁后的内存变化 (Dealloc - Alloc,理想情况值为0) ，可用于查看和记录比较单个ViewController内存占用情况以及潜在的内存泄漏，也可结合UI自动化测试使用
*	定时采样，采集当前ViewController和APP的内存，CPU
*	将原始数据以Excel格式保存到本地方便查看
*	只需pod，对项目代码无污染，仅在debug环境生效，建议在release环境删掉此pod库以较少APP体积
*	pod依赖了MLeaksFinder，可用于发现内存泄漏

# Usage
```
pod 'MFPerformanceMonitor', :configurations => ['Debug']
```

# Screenshots

入口

<img src="http://vviicc.qiniudn.com/menu@2x.png" width="300">

主界面

<img src="http://vviicc.qiniudn.com/main@2x.png" width="300">

Controller内存变化

<img src="http://vviicc.qiniudn.com/lifecycle@2x.png" width="300">

Controller定时采样

<img src="http://vviicc.qiniudn.com/sampling@2x.png" width="300">

APP定时采样

<img src="http://vviicc.qiniudn.com/app@2x.png" width="300">

本地保存为Excel 

<img src="http://vviicc.qiniudn.com/file@2x.png" width="300">

Excel文件查看 

<img src="http://vviicc.qiniudn.com/excel@2x.png" width="500">
