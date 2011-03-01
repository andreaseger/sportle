$(function () {
  $('.uprank').live('click', function(e){
    $.post('uprank', function(data) {
      $('.score').html(data);
    });
    e.preventDefault();
  });
});