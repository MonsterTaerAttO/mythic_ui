var cash = 0
var bank = 0

window.addEventListener('message', function (event) {


    switch(event.data.action) {
        case 'tick':
            $(".container").css("display", event.data.show ? "none" : "block");
            $("#boxHeal").css("width", event.data.health + "%");
            $("#boxArmor").css("width", event.data.armor + "%");
            $("#boxStamina").css("width", event.data.stamina + "%");
            break;
        case 'display':
            cash = event.data.cash;
            bank = event.data.bank;
    
            console.log('$' + cash);
    
            $('.cash').html('$' + formatCurrency(cash));
            $('.bank').html('$' + formatCurrency(bank));
            break;
        case 'change':
            var $element = $('<span class="' + event.data.type + '">$ ' + event.data.amount + '</span>');
            if (event.data.account === 'cash') {
                cash += event.data.amount;
    
                $('.cash-change').append($element);
                $('.cash').html('$' + formatCurrency(cash));
                setTimeout(function() {
                    $element.remove();
                }, 1000);
            } else {
                bank += event.data.amount;
                
                $('.bank-change').append($element);
                $('.bank').html('$' + formatCurrency(bank));
                setTimeout(function() {
                    $element.remove();
                }, 1000);
            }
            break
        case 'updateStatus':
            updateStatus(event.data.hunger, event.data.thirst);
            break;
        case 'hidecar':
            $('.car').hide();
            break;
        case 'showcar':
            $('.car').show();
            break;
        case 'showui':
            $('body').show();
            break;
        case 'hideui':
            $('body').hide();
            break;
        case 'toggle-seatbelt':
            if($('.seatbelt').hasClass('on')) {
                $('.seatbelt').addClass('off').removeClass('on');
            } else {
                $('.seatbelt').addClass('on').removeClass('off');
            }
            break;
        case 'set-seatbelt':
            if(!event.data.seatbelt) {
                $('.seatbelt').addClass('off').removeClass('on');
            } else {
                $('.seatbelt').addClass('on').removeClass('off');
            }
            break;
        case 'toggle-cruise':
            if($('.cruise').hasClass('on')) {
                $('.cruise').addClass('off').removeClass('on');
            } else {
                $('.cruise').addClass('on').removeClass('off');
            }
            break;
        case 'set-cruise':
            if(!event.data.cruise) {
                $('.cruise').addClass('off').removeClass('on');
            } else {
                $('.cruise').addClass('on').removeClass('off');
            }
            break;
        case 'set-voice':
            $("#boxVoice").css("width", event.data.value + "%");
            break;
        case 'voice-color':
            if (event.data.isTalking) {
                $('#boxVoice').addClass('active');
            } else {
                $('#boxVoice').removeClass('active');
            }
            break;
        case 'update-fuel':
            if(event.data.fuel < 100) {
                $('.fuel-val').html('0' + event.data.fuel);
            } else { 
                $('.fuel-val').html(event.data.fuel);
            }

            if(event.data.fuel <= 10) {
                $('.fuel-val').addClass('low');
            } else {
                $('.fuel-val').removeClass('low');
            }

            break;
        case 'update-speed':
            if (event.data.speed < 25) {
                $('.speed-val').html('00' + event.data.speed);
            } else if(event.data.speed < 100 && event.data.speed >= 10) {
                $('.speed-val').html('0' + event.data.speed);
            } else { 
                $('.speed-val').html(event.data.speed);
            }

            if(event.data.speed >= 100) {
                $('.speed-val').addClass('fast');
            } else {
                $('.speed-val').removeClass('fast');
            }
            break;
        case 'update-clock':
            $('.clock').html(event.data.time + ' <span class="ampm">' + event.data.ampm + '</span>')
            break;
        case 'update-position':
            if (event.data.street2 !== '') {
                $('.position').html(event.data.direction + ' <span class="seperator">|</span> ' + event.data.street1 + ' <span class="seperator2">-</span> ' + event.data.street2 + ' <span class="seperator">|</span> ' + event.data.area);
            } else {
                $('.position').html(event.data.direction + ' <span class="seperator">|</span> ' + event.data.street1 + ' <span class="seperator">|</span> ' + event.data.area);
            }
            break;
    }
});

function updateStatus(hunger, thirst){
    $('#boxHunger').css('width', hunger + '%')
    $('#boxThirst').css('width', thirst + '%')
}

function formatCurrency(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}