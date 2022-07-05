$(document).ready(function(){
    // $(".container").hide();
    $("#query").hide();
    $("#wanted-list").hide();
    $("#report").hide();
    $("body").css("background-color", "transparent");
    var current = "#recent"
    var citizen_name
    let citizenid
    var image
    var submit_type
    
    window.addEventListener("message", function(event){
        var data = event.data
        result = data.result
        if (data.type == "open") {
            var name = data.name
            document.getElementById("welcome-officer-name").innerHTML = "Welcome, " + name
            $(".container").fadeIn(250);
        } else if (data.type=="notify") {
            document.getElementById("notify-message").innerHTML = data.text
            $(".notify-container").show(250);
            setTimeout(() => {
                $(".notify-container").fadeOut(250);
            }, 9000);
        } else if (data.type == "search") {
            ListSearch(data.type2, data.results)
            if (data.mdt_image) {
                image = data.mdt_image
            }
        } else if (data.type == "loadinfo") {
            citizenid = data.identifier
            image = data.mdt_image
            SetCitizenInfo(data.info, data.identifier)
        } else if (data.type == "action") {
            AddAction(data.action, data.id)
        } else if (data.type == "wanted") {
            AddWanted(data.wanted, data.id)
        } else if (data.type == "dispatch") {
            AddDispatch(data.dispatches, data.id)
        } else if (data.type == "setup") {
            SetUpMDT(data.actions)
        } else if (data.type == "remove-wanted") {
            RemoveWanted(data.id)
        } else if (data.type == "cops") {
            ListCops(data.cops)
        } else if (data.type == "wanteds") {
            ListWanteds(data.wanteds)
        }
    });


   $(document).on("click", ".destroy", function (param) { 
       close()
    })

    document.onkeyup = function (data) {
        if (data.which == 13) { //enter
            if (current === "#query") {
                var val = document.activeElement.id
                if (val == "search-button-citizen-bar") {
                    type = "citizen"
                } else if (val == "search-button-vehicle-bar") {
                    type = "vehicle"
                }
                var value = document.getElementById(val).value
                Search(type, value)
            }
            
            return
        }
    };

    function SetCitizenInfo(info, identifier) {
        $(".any-text-vehicles").remove();
        $(".info-vehicles").remove();

        if (info.vehicles.length > 0 && info.vehicles !== "update") {
            for (let i = 0; i < info.vehicles.length; i++) {
                const element = info.vehicles[i];
                $(".citizen-info-name-area").append('<div class="info-vehicles"> ' + info.vehicles[i].plate + ' | ' + info.vehicles[i].modelname + ' </div>');
            }
        } else if (info.vehicles === false || info.vehicles == "" || info.vehicles == "update") {
            $(".citizen-info-name-area").append('<p class="any-text-vehicles" style="margin-top:0; padding-top: 5%; font-weight: 500"> Person has not got any vehicles! </p>');
        } 
        if (info.bolos && info.bolos !== "update") {
            $(".any-text-bolo").remove();
            $(".info-bolo-text").remove();
            $.each(info.bolos, function (k, v) { 
                let content = '<div class="info-bolo-text" id="bolo-' + k + '"><p class="delete-record" data-info='+k+'><i class="fas fa-times"></i> </p><p class="info-text"></p> <b>Fine</b> <br> <p> ' + v.title + '</p>  <br> <b>Purpose</b> <br> <p> ' + v.text + ' </p>  <br> </div>'
                $(".info-new-list-bolos").append(content);
                $(".info-bolo-text").find("[data-info="+k+"]").data("id", "#bolo-" + k);
                $(".info-bolo-text").find("[data-info="+k+"]").data("identifier", identifier);
                $(".info-bolo-text").find("[data-info="+k+"]").data("type", "bolos");
            });
        } else if (info.bolos === false || info.bolos == null) {
            $(".any-text-bolo").remove();
            $(".info-bolo-text").remove();
            $(".info-new-list-bolos").append('<p class="any-text-bolo"> Person has not got any bolos! </p>');
        }
        if (info.info && info.info !== "update") {
            $(".any-text-notes").remove();
            $(".info-note-text").remove();
            $.each(info.info, function (k, v) {
                let content = '<div class="info-note-text" id="note-' + k + '"><p class="delete-record" data-info='+k+'><i class="fas fa-times"></i> </p><p class="info-text"> '+ v +'</p></div>'
                $(".info-new-list-note").append(content);
                $(".info-note-text").find("[data-info="+k+"]").data("id", "#note-" + k);
                $(".info-note-text").find("[data-info="+k+"]").data("identifier", identifier);
                $(".info-note-text").find("[data-info="+k+"]").data("type", "notes");
            });
        } else if (info.info === false || info.info == null) {
            $(".any-text-notes").remove();
            $(".info-note-text").remove();
            $(".info-new-list-note").append('<p class="any-text-notes"> Person has not got any notes! </p>');
        }
        changePages("#info")
    }

    function close() { 
        $.post('http://fizzfau-mdt/close', JSON.stringify({display: false}));
        $(".container").fadeOut(500);
        setTimeout(() => {
            $(current).hide();
            current = "#recent"
            $(current).show();
        }, 500);

    }

    function warning(text) { 
        $("#warning").fadeIn(500);
        document.getElementById("warning").innerHTML = text
        setTimeout(() => {
            $("#warning").fadeOut(500);
        }, 3000);
    }

    $(document).on("click", ".delete-record", function (e) {
        var id = $(this).data('id')
        var identifier = $(this).data('identifier')
        var type = $(this).data('type')
        $.post('http://fizzfau-mdt/delete-record', JSON.stringify({id: id, identifier: identifier, type: type}));
        $(id).fadeOut(250);
    });

    $(document).on("click", ".header-button", function (e) {
        var selector = $(this).attr('name')
        if (selector == "#wanted-list" && current !== selector) {
            $.post('http://fizzfau-mdt/getWanteds');
        }
        changePages(selector)
    });

    $(document).on("click", ".change-recent-police", function (e) {
        var selector = $(this).attr('name')
        if (selector == "#active-polices") {
            $.post('http://fizzfau-mdt/getPolices');
        }
        changePages(selector)
    });

    $(document).on("click", "#note-inputs-submit", function (e) {
        var value = $('#note-text').val()
        if (value !== "") {
            let id = Math.floor(Math.random() * 999999);
            image = document.getElementById("user-image").src
            document.getElementById("note-text").value = ""
            $.post('http://fizzfau-mdt/add-note', JSON.stringify({id: id, value: value, identifier: citizenid, image: image, citizen_name:citizen_name}));
        } else {
            warning("Text area can not be empty!")
        }
    });

    $(document).on("click", "#bolo-inputs-submit", function (e) {
        var text = $('#bolo-text').val()
        var title = $('#bolo-title').val()
        image = $('#bolo-image').val()
        if (text !== "" && title !== "") {
            let bolo_id = Math.floor(Math.random() * 999999);
            if (image !== "") {
                if (!image.match(/.png/g) && !image.match(/.jpeg/g) && !image.match(/.jpg/g) && !image.match(/.gif/g)) {
                    image = "https://media.discordapp.net/attachments/610776060744957953/812758720626032690/unnamed.png"
                }
                document.getElementById("user-image").src = image
            }
            document.getElementById("bolo-text").value = ""
            document.getElementById("bolo-title").value = ""
            document.getElementById("bolo-image").value = ""
            image = document.getElementById("user-image").src
            $.post('http://fizzfau-mdt/add-bolo', JSON.stringify({id: bolo_id, text: text, image: image, title: title, identifier: citizenid, citizen_name:citizen_name}));
        } else {
            warning("Text area can not be empty!")
        }
    });

    function changePages(selector) { 
        if (selector !== "destroy") {
            if(selector !== current) {
                $(current).fadeOut(250);
                setTimeout(() => {
                    $(selector).fadeIn(250);      
                }, 250);
            } 
            current = selector
        } else {
            close()
        }
     }

    $(document).on("click", ".search-button", function (e) {
        var selector = $(this).attr('id')
        var value = document.getElementById(selector + "-bar").value
        var type = "vehicle"
        if (selector === "search-button-citizen") {
            type = "citizen"
        }
        // $(".search-results").css("height", "50%");
        Search(type, value)
    });

    $(document).on("click", ".back-action", function (e) {
        var selector = $(this).attr('id')
        $("."+selector).css("height", "0%");
        $("."+selector).css("opacity", "0.0");
        if (selector === "search-results") {
            $("#vehicle-search-label").css("margin-top", "5%");
        }
    });

    $(document).on("click", ".create-bolo", function (e) {
        var selector = $(this).attr('id')
        var text
        var label
        if (selector === "create-citizen-bolo") {
            submit_type = "citizen"
            text = "Citizen Name"
            label = "Create Citizen Bolo"
        } else {
            text = "Vehicle Plate"   
            label = "Create Vehicle Bolo"
            submit_type = "vehicle"
        }
        document.getElementById("report-name").placeholder = text
        document.getElementById("create-bolo-label").innerHTML = label
        changePages("#report")
    });

    $(document).on("click", ".wanted-submit", function (e) {
        var title = $("#report-name").val()
        var text = $("#report-desc").val()
        if (title !== "" && text !== "") {
            document.getElementById("report-name").value = ""
            document.getElementById("report-desc").value = ""
            $.post('http://fizzfau-mdt/add-wanted', JSON.stringify({title: title, text: text, type: submit_type}));
            warning("You succesfully created a wanted record!")
            setTimeout(() => {
                $("#warning").fadeOut();
            }, 1500);
        }
    });

    $(document).on("click", ".list-names", function (e) {
        var data = $(this).data("data")
        citizen_name = data.firstname + " " + data.lastname
        document.getElementById("name").innerHTML = data.firstname + " " + data.lastname
        document.getElementById("height").innerHTML = data.height
        document.getElementById("gender").innerHTML = data.sex
        document.getElementById("phone").innerHTML = data.phone_number
        document.getElementById("bank").innerHTML = "$" + data.accounts["bank"]
        document.getElementById("job").innerHTML = data.job
        fix()
        if (data.mdt_image !== null)  {
            image = data.mdt_image
            document.getElementById("user-image").src =  data.mdt_image
        }
        $.post('http://fizzfau-mdt/getInfo', JSON.stringify({identifier: data.identifier}));

        setTimeout(() => {
            changePages("#info")
            document.getElementById("search-button-citizen-bar").value = ""
        }, 250);
    });


    function Search(type, result) { 
        if (result !== "") {
            $.post('http://fizzfau-mdt/search-' + type, JSON.stringify({result: result}));
        } else {
            warning("Search bar cannot be empty!")
        }
    }

    function ListSearch(type, results) {
        if (results !== false) {
            fix(type)
            if (type=="citizen") {
                results.sort() 
                $(".list-names").remove();
                for (let i = 0; i < results.length; i++) {
                    $(".search-results").css("height", "50%");
                    $(".search-results").css("opacity", "1.0");
                    $("#vehicle-search-label").css("margin-top", "35%");
                    if (results[i].mdt_image === "" || results[i].mdt_image === undefined) {
                        results[i].mdt_image = "https://media.discordapp.net/attachments/610776060744957953/812758720626032690/unnamed.png"
                    }
                    $(".search-results").append('<div class="list-names" id="list-names-'+i+'"><img class="inner-image" src="' + results[i].mdt_image + '"><p class=""></img></p><p class="search-results-name"> ' + results[i].firstname + " " + results[i].lastname + ' </p><p class="search-results-bottom"></p></div>');
                    $("#list-names-"+i).data("data", results[i]);
                    if (i % 2 == 0) {
                        $("#list-names-"+i).css("background-color", "#e6e6e6");
                    }
                }
            } else if (type == "vehicle") {
                $(".vehicle-list").remove();
                for (let i = 0; i < results.length; i++) {
                    $(".vehicle-results").css("height", "100%");
                    $(".vehicle-results").css("opacity", "1.0");
                    $(".vehicle-results").append('<div class="vehicle-list" id="vehicle-list-'+i+'"><p class=""></p><p class="vehicle-results-plate"> ' + results[i].plate  + ' </p><p class="vehicle-results-model"> ' + results[i].modelname + ' </p><p class="vehicle-results-name"> ' + results[i].owner_name + ' </p></div>');
                    $("#vehicle-list-"+i).data("data", results[i]);
                    if (i % 2 == 0) {
                        $("#vehicle-list-"+i).css("background-color", "#e6e6e6");
                    }
                }
            }
        }
    }
    
    function fix(type) { 
        if (type == "citizen") {
            $(".vehicle-results").css("height", "0%");
            $(".vehicle-results").css("opacity", "0.0");
        } else if (type == "vehicle") {
            $(".search-results").css("height", "0%");
            $(".search-results").css("opacity", "0.0");
        } else {
            $(".search-results").css("height", "0%");
            $(".search-results").css("opacity", "0.0");
            $(".vehicle-results").css("height", "0%");
            $(".vehicle-results").css("opacity", "0.0");
        }
        $("#vehicle-search-label").css("margin-top", "5%");
    }

    function AddAction(actions, id) { 
        $(".new-actions").prepend('<div class="actions-js" id="actions-js-' + id +'"><p class="action-name">' + actions.name + '</p><p class="action-action"> ' + actions.type + ' </p><p class="timestamp" style="border:none; font-size: small">' + actions.time + '</p></div>');
        if (id % 2 == 1) {
            $("#actions-js-"+id).css("background-color", "rgb(216, 216, 216)");
        }
    }

    function AddWanted(wanteds, id) { 
        $(".new-wanteds").prepend('<div class="actions-js" id="actions-js-' + id +'"><p class="action-name">' + wanteds.title + '</p><p class="action-action"> ' + wanteds.text + ' </p><p class="timestamp" style="border:none; font-size: small">' + wanteds.time + '</p><p class="delete-wanted" data-info=' + id + '> <i class="fas fa-trash"></i> </p></div>');
        $(".actions-js").find("[data-info="+ id +"]").data("data", id);
        if (id % 2 == 1) {
            $("#actions-js-"+id).css("background-color", "rgb(216, 216, 216)");
        }
    }

    function AddDispatch(dispatch, id) { 
        $(".new-dispatches").prepend('<div class="dispatches-js"><p class="dispatch-code" style="border: none;">' + dispatch.data.code + '</p><p class="dispatch-label" style="border: none;">' + dispatch.data.name + '</p><p class="timestamp-dispatch" style="border: none; font-size: x-large;" data-id=' + id + '> <i class="fas fa-map-marker-alt"></i> </p></div>');
        $(".dispatches-js").find("[data-id="+id+"]").data("coords", dispatch.coords);
        if (id % 2 == 1) {
            $("#dispatches-js-"+id).css("background-color", "rgb(216, 216, 216)");
        }
    }

    function RemoveWanted(id) { 
        $("#actions-js-"+id).remove();
       // $("#actions-js-"+id).remove();
    }

    $(document).on("click", ".timestamp-dispatch", function (e) {
        var coords = $(this).data("coords")
        if (coords !== undefined) {
            // warning("Dispatch are located on your gps!")
            setTimeout(() => {
                $.post('http://fizzfau-mdt/waypoint', JSON.stringify({coords: coords}));
                close() 
            }, 1500);
        }
    });

    $(document).on("click", ".delete-wanted", function (e) {
        var id = $(this).data("data")
        $("#actions-js-"+id).remove();
        $.post('http://fizzfau-mdt/delete-wanted', JSON.stringify({id: id}));
        RemoveWanted(id)
    });

    function SetUpMDT(actions) {
        for (let index = actions.length; 0 <= index; index--) {
            if (actions[index] !== undefined) {
                $(".new-actions").append('<div class="actions-js" id="actions-js-' + index + '"><p class="action-name">' + actions[index].name + '</p><p class="action-action"> ' + actions[index].type + ' </p><p class="timestamp" style="border:none; font-size: small">' + actions[index].time + '</p></div>');
            }
            if (index % 2 == 0) {
                $("#actions-js-"+index).css("background-color", "rgb(216, 216, 216)");
            }
        }
    }

    function ListCops(cops) { 
        $(".actions-cops").remove();
        for (let index = 0; index < cops.length; index++) {
            $("#cops-online").append('<div class="actions-cops" style="border: none" id="cop-div-'+index+'"><p class="officer-name" style="border: none;" >'+cops[index].name + '</p><p class=""></p><p class="timestamp" style="border: none;">'+cops[index].rank + '</p>');
            if (index % 2 == 0) {
                $("#cop-div-"+index).css("background-color", "rgb(216, 216, 216)");
            }
        }
    }

    function ListWanteds(wanteds) { 
        $(".new-wanteds").find(".actions-js").remove();
        var content
        $.each(wanteds, function (k, v) { 
            if (v !== null) {
                if (v.type == "vehicle") {
                    content = '<span class="wanted-icon-vehicle"><i class="fas fa-car-alt"></i></span>'
                } else {
                    content = '<span class="wanted-icon-citizen"><i class="fas fa-user"></i></span>'
                }
                $(".new-wanteds").prepend('<div class="actions-js" id="actions-js-' + k + '">' + content + '<p class="action-name">' + v.title + '</p><p class="action-action"> ' + v.text + ' </p><p class="timestamp" style="border:none; font-size: small">' + v.time + '<p class="delete-wanted" data-info=' + k + '> <i class="fas fa-trash"></i> </p> </p></div> ');
                $(".actions-js").find("[data-info="+ k +"]").data("data", k);
                if (k % 2 == 0) {
                    $("#wanted-js-"+k).css("background-color", "rgb(216, 216, 216)");
                }
            }
        });
    }
})