$(function () {
  $('.uprank').live('click', function(e){
  	url = $('.uprank')[0].href
    $.post( url, function(data) {
      $('.score').html(data);
    });
    e.preventDefault();
  });
});