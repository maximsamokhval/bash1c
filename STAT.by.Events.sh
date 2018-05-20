echo "Распределение событий по количеству"
time grep -r ".*" -H /c/v8/logs/*/*.log  | \
perl -ne '
    use 5;
    s/\xef\xbb\xbf//;                               #BOM - обязательно в начале, иначе с певой строкой будут проблемы
    if(/log:\d\d:\d\d\.\d+-\d+,(\w+),/){            #если в строке есть идентификатор начала строки и это наш тип события
        if(//){                                     #первоначальный отбор по событиям            
            s/\s+/ /g;                              #сворачиваю много пробелов в один, и перенос строки тоже здесь улетит в пробел
            if(s/^.*\/(\w+)_(\d+)\/(\d{2})(\d{2})(\d{2})(\d{2})\.log\:\s*(\d+:\d+\.\d+)\-(\d+),(\w+),(\d+)//){
                $_="\r\n".",dt=20".$3.".".$4.".".$5.",time=".$6.":".$7.",prc=".$1.",pid=".$2.",dur=".$8.",evnt=".$9.",ukn=".$10.$_ ;
            }#добавляю в строки событий dt=ГГГГ.ММ.ДД,time=ЧЧ:ММ:СС.МКСМКС,prc=ИмяПпроцессаИзПути,pid=PidПроцессаИзПути и форматирую dur=длительность,evnt=событие
            $f=1;
        }else{$f=0};
    }
    elsif($f) {                                     #если наше событие, то обрабатываем эту висячую  строку
        s/^.*log://;                                #из перенесённых строк просто вытираю начало
        s/\s+/ /g;                                  #сворачиваю много пробелов в один, и перенос строки тоже здесь улетит в пробел
    }
    if($f){
        s/\x27//g;                                  #убираю апострофы
        print;
    }END{print "\r\n"}                              #надо поставить, чтобы последняя строка в обработку попала
' | \
perl -ne '                                          #perl умеет работать как AWK
    use 5;
    if(/dur=(\d+),evnt=(\w+)/){
        $dur_ttl+=$1/1000;
        $dur{$2}+=$1/1000;
        $cnt_ttl+=1;
        $cnt{$2}+=1;
    }
    END{
        printf("=====TIME TOTAL(ms):%.2f      COUNT:%d      AVG(ms):%.2f\r\n",
            $dur_ttl,
            $cnt_ttl,
            $dur_ttl/$cnt_ttl);                     #формирую заголовок
        foreach $k (sort {$cnt{$b} <=> $cnt{$a}} keys %dur) {
            last if ($_+=1)>10;                     #но только первые 10 строк
            printf "$_: [][][] TIME(ms):%d [][][] TIME(%):%.2f [][][] COUNT:%d [][][] COUNT(%):%.2f [][][] BY:$k \r\n",
            $dur{$k},
            $dur{$k}/($dur_ttl>0?$dur_ttl:1)*100,
            $cnt{$k},
            $cnt{$k}/($cnt_ttl>0?$cnt_ttl:1)*100;   #сортирую массив по убыванию длительности и вывожу его
        }
    }'
