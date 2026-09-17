async function SendData(data, cb) {
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (cb) cb(xhr.responseText);
        }
    };
    xhr.open("POST", 'https://renzu_multicharacter/nuicb', true);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.send(JSON.stringify(data));
}

let getEl = function (id) { return document.getElementById(id); };
let myForm = getEl('registerf');
let chosenslot = 1;
let characters = {};
let i18n = {};
let lastSpawnCoord = null;

const toDataURL = url => fetch(url)
    .then(response => response.blob())
    .then(blob => new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result);
        reader.onerror = reject;
        reader.readAsDataURL(blob);
    }));

let pedshots = {};

// ---------------------------------------------------------------------
// i18n
// ---------------------------------------------------------------------
function applyI18n() {
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (i18n[key]) el.textContent = i18n[key];
    });
    document.querySelectorAll('[data-i18n-placeholder]').forEach(el => {
        const key = el.getAttribute('data-i18n-placeholder');
        if (i18n[key]) el.placeholder = i18n[key];
    });
    document.querySelectorAll('[data-i18n-value]').forEach(el => {
        const key = el.getAttribute('data-i18n-value');
        if (i18n[key]) el.value = i18n[key];
    });
}

function t(key, fallback) {
    return i18n[key] || fallback || key;
}

// ---------------------------------------------------------------------
// nationalities (now data-driven from shared/nationalities.json, no more
// hardcoded 190-line list baked into the page)
// ---------------------------------------------------------------------
function populateNationalities(list) {
    const select = getEl('selectCountry');
    if (!select || !Array.isArray(list)) return;
    for (const country of list) {
        const option = document.createElement('option');
        option.textContent = country;
        option.setAttribute('value', country);
        select.appendChild(option);
    }
}

window.addEventListener('message', function (table) {
    let event = table.data;

    if (event.i18n) {
        i18n = event.i18n;
        applyI18n();
    }
    if (event.nationalities) {
        populateNationalities(event.nationalities);
    }
    if (event.bgmusic) {
        const audio = getEl('bgmusic');
        audio.src = event.sound;
        audio.volume = event.volume ?? 0.5;
        audio.play().catch(() => { /* autoplay may be blocked until user interaction */ });
    }

    if (event.fade) {
        getEl('body').style.display = 'block';
        getEl('logocontainer').style.display = 'none';
        getEl('loading').style.display = 'block';
        getEl('body').style.background = 'rgba(0, 0, 0, 1.0)';
    } else if (event.fade === false) {
        getEl('loading').style.display = 'none';
        getEl('body').style.background = 'rgba(0, 0, 0, 0.0)';
    }
    if (event.pedshots) {
        if (event.default) {
            pedshots[event.slot] = '/web/ped.jpg';
        } else if (pedshots[event.slot] === undefined || pedshots[event.slot] === '/web/ped.jpg') {
            toDataURL(`https://nui-img/${event.pedshots}/${event.pedshots}?${Date.now()}`)
                .then(dataUrl => { pedshots[event.slot] = dataUrl; });
        }
    }
    if (event.showui) {
        getEl('characters').innerHTML = '';
        getEl('body').style.display = 'block';
        getEl('multi').style.display = 'none';
        getEl('logocontainer').style.display = 'none';
        getEl('charinfo').style.display = 'none';
        getEl('option').style.display = 'none';
        getEl('logocontainer').style.width = '100%';
        getEl('logocontainer').style.right = 'auto';
        getEl('register').style.display = 'none';
    }
    if (event.delete === false) {
        getEl('deletebutton').style.display = 'none';
        getEl('deletecancel').style.transform = 'translate(0, 50px)';
        getEl('confirm').style.textAlign = 'center';
        getEl('candelete').textContent = t('delete_disabled', 'Player cannot delete characters. Contact administrator');
    }
    if (event.show === true) {
        getEl('multi').style.display = 'grid';
    } else if (event.show === false) {
        getEl('multi').style.display = 'none';
    }
    if (event.showlogo === true) {
        getEl('logocontainer').style.top = '20%';
        getEl('logocontainer').style.display = 'inline-block';
    } else if (event.showlogo === false) {
        getEl('logocontainer').style.display = 'inline-block';
        getEl('logocontainer').style.width = '45vh';
        getEl('logocontainer').style.right = '15%';
        getEl('logocontainer').style.top = '35%';
    }
    if (event.data) {
        renderCharacters(event.data);
    }
    if (event.showcharacter?.showoptions === 'existing') {
        getEl('delete').style.display = 'inline-block';
        getEl('register').style.display = 'none';
        getEl('charinfo').style.display = 'unset';
        getEl('logocontainer').style.display = 'none';
        getEl('option').style.display = 'inline-block';
        getEl('registercustom').style.display = 'none';
        chosenslot = event.showcharacter.slot;
        ShowInfos();
    } else if (event.showcharacter?.showoptions === 'new') {
        chosenslot = event.showcharacter.slot;
        if (event.showcharacter.customregister) {
            getEl('delete').style.display = 'none';
            getEl('charinfo').style.display = 'none';
            getEl('logocontainer').style.display = 'none';
            getEl('option').style.display = 'none';
            getEl('registercustom').style.display = 'block';
        } else if (event.showcharacter.customregister === false) {
            getEl('register').style.display = 'flex';
            getEl('delete').style.display = 'none';
            getEl('charinfo').style.display = 'none';
            getEl('logocontainer').style.display = 'none';
            getEl('option').style.display = 'none';
        }
    }

    // ---------------- integrated spawn selector ----------------
    if (event.showspawns === false) {
        getEl('spawncontainer').style.display = 'none';
    } else if (event.showspawns) {
        lastSpawnCoord = event.lastloc || null;
        renderSpawns(event.showspawns);
        getEl('body').style.display = 'block';
        getEl('multi').style.display = 'none';
        getEl('option').style.display = 'none';
        getEl('charinfo').style.display = 'none';
        getEl('registercustom').style.display = 'none';
        getEl('register').style.display = 'none';
        getEl('logocontainer').style.display = 'none';
        getEl('spawncontainer').style.display = 'block';
    }
});

function renderCharacters(data) {
    let chars = data?.characters || {};
    characters = chars;
    let slots = data.slots === undefined ? 5 : data.slots;
    for (let i = 0; i < slots; i++) {
        if (!chars[i] || chars[i].name === undefined) {
            chars[i] = { name: t('empty_slot', 'Empty Slot') };
        }
    }
    for (const i in chars) {
        let index = i;
        let ui = `<div class="char__card">
        <div class="char__data" onclick="showchar('${index}')">
            <img src="${pedshots[index]}" alt="" class="char__img" onerror="this.src='/web/ped.jpg';">
            <div id="playerinfo">
            <h1 class="char__name">${chars[index]?.name || t('empty_slot', 'Empty Slot')}</h1>
            <span class="char__profession">${chars[index]?.job || ''}</span>
            </div>
        </div>
        <div class="extras" id="extras_${i}"></div>
        </div>`;
        getEl('characters').insertAdjacentHTML("beforeend", ui);
        for (const ex in chars[index]?.extras || {}) {
            if (chars[index].extras[ex]) {
                let exui = `<a href="#" class="char__extras with-tooltip" data-tooltip-content="${ex}">${data.extras[ex]}</a>`;
                getEl(`extras_${i}`).insertAdjacentHTML("beforeend", exui);
            }
        }
    }
}

function ShowInfos() {
    getEl('infos').innerHTML = '';
    let id = chosenslot - 1;
    let infos = {};
    const rows = [
        ['name', 'fa-id-card', 'name'],
        ['job', 'fa-briefcase', 'job'],
        ['grade', 'fa-level-up-alt', 'grade'],
        ['sex', 'fa-venus-mars', 'sex'],
        ['money', 'fa-wallet', 'money'],
        ['bank', 'fa-piggy-bank', 'bank'],
        ['dateofbirth', 'fa-calendar-week', 'birthdate'],
    ];
    for (const [field, icon, labelKey] of rows) {
        if (characters[id] && characters[id][field] !== undefined) {
            let data = characters[id][field];
            if (field === 'money' || field === 'bank') data = numberWithCommas(data);
            infos[field] = { label: `<i class="fas ${icon}"></i> ${t(labelKey, field)}`, data };
        }
    }
    for (const i in infos) {
        let ui = `<div style="justify-content: space-between!important;border-bottom: 1px solid #dee2e6!important;padding-bottom: 0.5rem!important;margin-top: 1rem!important;align-items: center!important;display: flex!important;width: 300px;">
                <h1 class="char__name">${infos[i].label}</h1>
                <span class="char__profession">${infos[i].data}</span>
            </div>`;
        getEl('infos').insertAdjacentHTML("beforeend", ui);
    }
}

function stopBgMusic() {
    const audio = getEl('bgmusic');
    audio.pause();
    audio.currentTime = 0;
}

function chooseslot() {
    stopBgMusic();
    getEl('body').style.display = 'none';
    return SendData({ msg: 'chooseslot', slot: chosenslot });
}

function confirm(show) {
    if (show) {
        getEl('confirm').style.display = 'block';
        SendData({ msg: 'deleteattempt' });
    } else {
        getEl('confirm').style.display = 'none';
    }
}

function deletechar() {
    getEl('confirm').style.display = 'none';
    return SendData({ msg: 'deletechar', slot: chosenslot });
}

function showchar(slot) {
    slot = +slot + 1;
    chosenslot = slot;
    myForm.reset();
    return SendData({ msg: 'showchar', slot: chosenslot });
}

function register() {
    let formData = new FormData(myForm);
    let data = Object.fromEntries(formData);
    let ok = true;
    for (const i in data) {
        if (data[i] === '') {
            ok = false;
            getEl(i).style.borderColor = 'red';
            getEl(i).style.borderStyle = 'outset';
            setTimeout(() => {
                getEl(i).style.borderColor = 'unset';
                getEl(i).style.borderStyle = 'unset';
            }, 2000);
        }
    }
    if (ok) {
        stopBgMusic();
        getEl('body').style.display = 'none';
        myForm.reset();
        return SendData({ msg: 'create', info: data, slot: chosenslot });
    }
}

function registercustom() {
    stopBgMusic();
    getEl('body').style.display = 'none';
    getEl('registercustom').style.display = 'none';
    return SendData({ msg: 'create', info: { sex: 'm' }, slot: chosenslot });
}

function numberWithCommas(x) {
    return (x ?? 0).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

// ---------------------------------------------------------------------
// integrated spawn selector (formerly the standalone renzu_spawn NUI)
// ---------------------------------------------------------------------
function renderSpawns(spawns) {
    getEl('spawn').innerHTML = '';
    for (const i in spawns) {
        let data = spawns[i];
        let ui = `<div class="card">
        <div class="card-img" style="background:url(/web/images/${data.name}.png);background-size: cover;" onclick="spawnPreview('${data.name}')"></div>
        <div class="card-title"><h2>${data.label}</h2></div>
        <div class="card-text"><p>${t('spawn_info_prefix', 'Info')}: ${data.info}</p></div>
        <button type="button" class="card-btn" onclick="spawnSelect('${data.name}')">${t('spawn_button', 'Spawn')}</button>
    </div>`;
        getEl('spawn').insertAdjacentHTML("beforeend", ui);
    }
    containerChildValue = document.querySelectorAll('.card');
    if (containerChildValue.length) cardWidth = document.querySelector('.card').offsetWidth;
}

function spawnPreview(name) {
    SendData({ msg: 'spawnpreview', name: name, coord: name === 'lastloc' ? lastSpawnCoord : null });
}

function spawnSelect(name) {
    getEl('spawncontainer').style.display = 'none';
    getEl('body').style.display = 'none';
    SendData({ msg: 'spawnselect', name: name, coord: name === 'lastloc' ? lastSpawnCoord : null });
}

// card carousel (unchanged behaviour from the original spawn UI)
let cardWidth = '';
let containerChildValue = '';
let count = 0;
let tracker = 0;

document.addEventListener('DOMContentLoaded', () => {
    const prev = document.querySelector('.prev');
    const next = document.querySelector('.next');
    if (!prev || !next) return;

    const toLeft = function () {
        count = count - (cardWidth - 75);
        tracker++;
        prev[tracker === 0 ? 'setAttribute' : 'removeAttribute']('disabled', '');
        if (tracker === containerChildValue.length - 1) next.setAttribute('disabled', '');
        else next.removeAttribute('disabled');
        document.querySelectorAll('.card').forEach(el => { el.style.transform = `translateX(${count}px)`; });
    };

    const toRight = function () {
        count = count + (cardWidth - 75);
        tracker--;
        if (tracker <= 0) prev.setAttribute('disabled', '');
        else prev.removeAttribute('disabled');
        if (tracker === containerChildValue.length - 2) next.setAttribute('disabled', '');
        else next.removeAttribute('disabled');
        document.querySelectorAll('.card').forEach(el => { el.style.transform = `translateX(${count}px)`; });
    };

    prev.addEventListener('click', () => toRight());
    next.addEventListener('click', () => toLeft());
});
