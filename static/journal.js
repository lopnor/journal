$(function(){
    $.fn.oembed.registerProvider(
        'nicovideo', 'www.nicovideo.jp', 'http://oembed.soffritto.org/oembed');
    $.fn.oembed.registerProvider(
        'pixiv', 'www.pixiv.net', 'http://oembed.soffritto.org/oembed');
    $('div.markdown').find('a').oembed(null,{ embedMethod: "append" });
});
