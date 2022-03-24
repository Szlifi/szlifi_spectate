$(function(){

	$('.users').on('click', '.spec', function(){
		let target = $(this).data('spectate');
		let player = $('.spectate').attr('id');
		if (target == player) {
			var message = 'Magadat nem spectételheted.';
			$.post('http://hrp_spectate/message', JSON.stringify({msg: message}));
		} else {
			$('.spectate').fadeOut();
			$.post('http://hrp_spectate/select', JSON.stringify({id: target}));
		}
	});

	$('.header').on('click', '#close', function(){
		$('.spectate').fadeOut();
		$.post('http://hrp_spectate/quit');
	});

	window.addEventListener('message', function(event){
		if (event.data.type == "show"){
			let data = event.data.data;
			let player = event.data.player;
			$('.spectate').attr('id', player);
			populate(data);
			setTimeout(function(){
				$('.spectate').fadeIn();
			}, 50)
		}
	});

	$(document).keyup(function(e){
		if (e.keyCode == 27){
			$('.spectate').fadeOut();
			$.post('http://hrp_spectate/close');
		}
	})

});

function showSrollAnim() {
	if (document.getElementById('users').scrollHeight > document.getElementById('users').clientHeight) {
		$('.scrollHelp').fadeIn();
	} else {
		$('.scrollHelp').fadeOut();
	}
}

function populate(data){
	$('.spectate .users').html('');

	data.sort(function(a, b) {
		let idA = a.id;
		let idB = b.id;
		if (idA < idB)
	        return -1 
	    if (idA > idB)
	        return 1
	    return 0
	});

	formatter = new Intl.NumberFormat('en-US', {
		style: 'currency',
		currency: 'USD',
	  });
	
	for (var i = 0; i < data.length; i++) {
		let id = data[i].id;
		let name = data[i].name;
		let jobText = data[i].jobText;
		let money = data[i].money;
		let bank = data[i].bank;

		let element = 	'<div class="user">' +
							'<span class="user-id">'+ '[Id]: ' + id + '</span>' +
							'<span class="user-name">'+ '[Név]: ' + name + '</span>' +
							'<span class="user-jobText">'+ '[Munka]: ' + jobText + '</span>' +
							'<span class="user-money">'+ '[Kézpénz]: ' + formatter.format(money) + '</span>' +
							'<span class="user-money">'+ '[Bankkártya]: ' + formatter.format(bank) + '</span>' +
							'<span class="user-actions">' +
								'<input type="submit" class="spec" data-spectate="' + id + '" value="Spectate">' +
							'</span>' +
						'</div>';

		$('.spectate .users').append(element);
	}
	showSrollAnim()
}

$(function () {
	$(".spectate").draggable();
  });
  