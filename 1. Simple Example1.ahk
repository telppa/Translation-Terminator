; Translate text from Japanese to English.
MsgBox,% BaiduTranslator.translate("今日の天気はとても良いです", "ja", "en")

ExitApp

#Include <BaiduTranslator>



/*
-------------------------------------------------------------------------
Language abbreviations may be different in different libraries.

However, the following common languages always use the same abbreviations in different libraries.

阿拉伯语     ar  Arabic
爱沙尼亚语   et  Estonian
保加利亚语   bg  Bulgarian
波兰语       pl  Polish
丹麦语       da  Danish
德语         de  German
俄语         ru  Russian
法语         fr  French
芬兰语       fi  Finnish
韩语         ko  Korean
荷兰语       nl  Dutch
捷克语       cs  Czech
拉脱维亚语   lv  Latvian
立陶宛语     lt  Lithuanian
罗马尼亚语   ro  Romanian
葡萄牙语     pt  Portuguese
日语         ja  Japanese
瑞典语       sv  Swedish
斯洛伐克语   sk  Slovak
斯洛文尼亚语 sl  Slovenian
泰语         th  Thai
土耳其语     tr  Turkish
乌克兰语     uk  Ukrainian
西班牙语     es  Spanish
希腊语       el  Greek
匈牙利语     hu  Hungarian
意大利语     it  Italian
印尼语       id  Indonesian
英语         en  English
越南语       vi  Vietnamese
中文         zh  Chinese

*/