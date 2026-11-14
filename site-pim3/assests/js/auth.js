const api = '/api/site/auth';
const form = document.querySelector('[data-auth]');
const errorMessage = document.querySelector('[data-auth-error]');
const sessionPanel = document.querySelector('[data-auth-session]');
const establishments = document.querySelector('[data-establishments]');
const establishmentList = establishments?.querySelector('[data-establishment-list]');
const establishmentStatus = establishments?.querySelector('[data-establishment-status]');
const establishmentMore = establishments?.querySelector('[data-establishment-more]');
const creation = establishments?.querySelector('[data-create-establishment]');
const establishmentFeedback = establishments?.querySelector('[data-establishment-feedback]');
const photoFormTemplate = document.querySelector('#estabelecimento-enviar-foto');
let establishmentRequest;
let establishmentPage = 1;

const maxPhotoSize = 5 * 1024 * 1024;

async function request(path, options) {
    const response = await fetch(`${api}/${path}`, options);
    if (response.status === 204) return null;

    const result = await response.json().catch(() => null);
    if (response.ok && result) return result;
    if (response.status === 401 && path === 'sessao') return null;
    if (response.status === 429) throw new Error('Muitas tentativas. Tente novamente em um minuto.');
    throw new Error(result?.message || 'Não foi possível concluir. Tente novamente.');
}

function showError(message) {
    errorMessage.textContent = message;
    errorMessage.hidden = !message;
}

function showMessage(element, message) {
    element.textContent = message;
    element.hidden = !message;
}

function fileAsBase64(file) {
    if (file.size > maxPhotoSize) throw new Error('Escolha uma foto de até 5 MB.');
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result.split(',')[1]);
        reader.onerror = () => reject(new Error('Não foi possível ler a foto.'));
        reader.readAsDataURL(file);
    });
}

function wirePhotoPicker(editor, error) {
    const picker = editor.querySelector('[data-photo-picker]');
    const input = editor.elements.arquivo;
    const preview = picker.querySelector('[data-photo-preview]');
    const action = picker.querySelector('[data-photo-action]');
    const filename = picker.querySelector('[data-photo-name]');
    const remove = picker.querySelector('[data-remove-photo]');
    const defaultAction = action.textContent;
    let previewUrl;

    function clearPreview() {
        if (previewUrl) URL.revokeObjectURL(previewUrl);
        previewUrl = undefined;
        preview.hidden = true;
        preview.removeAttribute('src');
        input.setCustomValidity('');
        remove.hidden = true;
        action.textContent = defaultAction;
        showMessage(filename, '');
        showMessage(error, '');
    }

    input.addEventListener('change', () => {
        clearPreview();
        const file = input.files[0];
        if (!file) return;
        if (file.size > maxPhotoSize) {
            input.value = '';
            const message = 'Escolha uma foto de até 5 MB.';
            input.setCustomValidity(message);
            remove.hidden = false;
            showMessage(error, message);
            return;
        }
        previewUrl = URL.createObjectURL(file);
        preview.src = previewUrl;
        preview.hidden = false;
        remove.hidden = false;
        action.textContent = 'Trocar foto';
        showMessage(filename, file.name);
    });

    preview.addEventListener('error', () => {
        if (!previewUrl) return;
        input.value = '';
        clearPreview();
        const message = 'Selecione uma foto JPG, PNG ou WebP válida.';
        input.setCustomValidity(message);
        remove.hidden = false;
        showMessage(error, message);
    });
    remove.addEventListener('click', () => {
        input.value = '';
        clearPreview();
        input.focus();
    });
    editor.addEventListener('reset', clearPreview);
}

function clearEstablishmentCards() {
    for (const editor of establishmentList.querySelectorAll('form')) editor.reset();
    establishmentPage = 1;
    establishmentList.replaceChildren();
    establishmentList.hidden = true;
}

function wireEstablishmentForm(details, path, message, prepare) {
    const editor = details.querySelector('form');
    const submit = editor.querySelector('button[type="submit"]');
    const error = editor.querySelector('[role="alert"]');
    const label = submit.textContent;
    wirePhotoPicker(editor, error);
    editor.addEventListener('submit', async (event) => {
        event.preventDefault();
        if (submit.disabled) return;
        submit.disabled = true;
        submit.textContent = 'Salvando…';
        showMessage(error, '');
        showMessage(establishmentFeedback, '');
        try {
            const fields = new FormData(editor);
            const file = fields.get('arquivo');
            fields.delete('arquivo');
            const body = Object.fromEntries(fields);
            if (file?.name) body.arquivo = await fileAsBase64(file);
            prepare?.(body);
            await request(path, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body),
            });
            editor.reset();
            details.open = false;
            if (establishments.hidden) return;
            showMessage(establishmentFeedback, message);
            clearEstablishmentCards();
            await loadEstablishments();
        } catch (failure) {
            showMessage(error, failure instanceof TypeError ? 'Não foi possível conectar ao servidor.' : failure.message);
        } finally {
            submit.disabled = false;
            submit.textContent = label;
        }
    });
}

function establishmentCard(row) {
    const item = document.createElement('li');
    item.className = 'establishment-card';
    const body = document.createElement('div');
    body.className = 'establishment-card-body';
    const gallery = document.createElement('div');
    gallery.className = 'establishment-gallery';
    const cover = document.createElement('div');
    cover.className = 'establishment-card-cover establishment-card-empty';
    cover.innerHTML = '<i class="bi bi-image" aria-hidden="true"></i> Sem foto de capa';
    item.append(cover, body);

    const name = document.createElement('h2');
    name.className = 'establishment-card-name';
    name.textContent = row.name;
    body.append(name);
    for (const detail of [row.category, row.address, row.description].filter(Boolean)) {
        const line = document.createElement('p');
        line.className = 'establishment-card-detail';
        line.textContent = detail;
        body.append(line);
    }

    for (const photo of row.fotos.filter(photo => photo.url)) {
        const url = new URL(photo.url, location.origin);
        if (url.origin !== location.origin && url.protocol !== 'https:') continue;
        const image = document.createElement('img');
        image.alt = photo.legenda || `Foto de ${row.name}`;
        image.loading = 'lazy';
        if (cover.parentNode === item) {
            image.className = 'establishment-card-cover';
            image.addEventListener('error', () => image.replaceWith(cover), { once: true });
            cover.replaceWith(image);
        } else {
            image.addEventListener('error', () => image.remove(), { once: true });
            gallery.append(image);
        }
        image.src = url.href;
    }
    if (gallery.childElementCount) body.append(gallery);

    const photoEditor = photoFormTemplate.content.firstElementChild.cloneNode(true);
    wireEstablishmentForm(photoEditor, `estabelecimentos/${row.id}/fotos`, 'Foto enviada.');
    body.append(photoEditor);
    return item;
}

if (creation) {
    wireEstablishmentForm(creation, 'estabelecimentos', 'Estabelecimento salvo.', (body) => {
        body.categoriaId = Number(body.categoriaId);
    });
    const categories = creation.querySelector('select');
    creation.addEventListener('toggle', async () => {
        if (!creation.open || categories.options.length > 1 || categories.disabled) return;
        const error = creation.querySelector('[role="alert"]');
        const submit = creation.querySelector('button[type="submit"]');
        categories.disabled = true;
        submit.disabled = true;
        showMessage(error, '');
        try {
            const response = await fetch('/api/restaurantes/categorias');
            if (!response.ok) throw new Error();
            for (const category of await response.json()) {
                categories.add(new Option(category.nome, category.id));
            }
            if (categories.options.length === 1) showMessage(error, 'Nenhuma categoria disponível.');
        } catch {
            showMessage(error, 'Não foi possível carregar as categorias. Feche e abra o formulário para tentar novamente.');
        } finally {
            categories.disabled = false;
            submit.disabled = false;
        }
    });
}

async function loadEstablishments() {
    establishmentRequest?.abort();
    const controller = new AbortController();
    establishmentRequest = controller;
    establishmentMore.hidden = true;
    establishmentStatus.textContent = 'Carregando estabelecimentos…';

    try {
        const rows = await request(`estabelecimentos?pagina=${establishmentPage}`, { signal: controller.signal });
        if (controller.signal.aborted) return;

        establishmentList.append(...rows.map(establishmentCard));

        const empty = !establishmentList.childElementCount;
        establishmentList.hidden = empty;
        establishmentStatus.textContent = empty ? 'Você ainda não tem um estabelecimento. Clique em Criar estabelecimento para começar.' : '';
        establishmentMore.textContent = 'Ver mais';
        establishmentMore.hidden = rows.length < 50;
        establishmentPage++;
    } catch {
        if (controller.signal.aborted) return;
        establishmentStatus.textContent = 'Não foi possível carregar seus estabelecimentos.';
        establishmentMore.textContent = 'Tentar novamente';
        establishmentMore.hidden = false;
    }
}

establishmentMore?.addEventListener('click', loadEstablishments);

function showSession(session) {
    for (const link of document.querySelectorAll('nav a[href="login.html"]')) {
        link.lastChild.textContent = session ? ' Minha conta' : 'Login';
    }

    if (session && form?.dataset.auth === 'registar') {
        location.replace('login.html');
        return;
    }
    if (!sessionPanel) return;

    form.hidden = Boolean(session);
    sessionPanel.hidden = !session;
    establishmentRequest?.abort();
    clearEstablishmentCards();
    creation.open = false;
    creation.querySelector('form').reset();
    showMessage(establishmentFeedback, '');
    establishments.hidden = session?.role !== 'Proprietario';
    if (!establishments.hidden) loadEstablishments();
    if (session) {
        const account = session.role === 'Proprietario' ? 'Estabelecimento (CNPJ)' : 'Cliente (CPF)';
        sessionPanel.querySelector('[data-auth-user]').textContent = `Olá, ${session.name}. ${account}`;
    }
}

if (form) {
    const type = form.elements.tipoConta;
    const documentInput = form.elements.documento;
    const documentLabel = form.querySelector('label[for="documento"]');
    const submit = form.querySelector('button[type="submit"]');

    function updateDocumentField() {
        const owner = type.value === 'Proprietario';
        documentLabel.textContent = owner ? 'CNPJ do estabelecimento' : 'CPF do cliente';
        documentInput.placeholder = owner ? 'CNPJ' : 'CPF';
        const link = form.querySelector('a[href^="conta.html"], a[href^="login.html"]');
        const page = form.dataset.auth === 'login' ? 'conta.html' : 'login.html';
        link.href = owner ? `${page}?tipo=cnpj` : page;
    }

    if (new URLSearchParams(location.search).get('tipo') === 'cnpj') type.value = 'Proprietario';
    updateDocumentField();
    type.addEventListener('change', () => {
        documentInput.value = '';
        updateDocumentField();
        showError('');
    });

    form.addEventListener('submit', async (event) => {
        event.preventDefault();
        if (submit.disabled) return;
        showError('');

        const fields = new FormData(form);
        const role = type.value;
        const owner = role === 'Proprietario';
        const digits = documentInput.value.replace(/[.\/\s-]/g, '');
        const expectedDigits = owner ? 14 : 11;
        if (digits.length !== expectedDigits || !/^\d+$/.test(digits)) {
            showError(`Informe os ${expectedDigits} dígitos do ${owner ? 'CNPJ' : 'CPF'}.`);
            documentInput.focus();
            return;
        }

        const senha = fields.get('senha');
        const cadastro = form.dataset.auth === 'registar';
        const body = { email: fields.get('email').trim(), senha, role };
        if (cadastro) {
            if (senha !== fields.get('confirmarSenha')) {
                showError('As senhas precisam ser iguais.');
                form.elements.confirmarSenha.focus();
                return;
            }
            body.nome = fields.get('nome').trim();
            body[owner ? 'documento' : 'cpf'] = digits;
        } else {
            body.documento = digits;
        }

        submit.disabled = true;
        try {
            await request(form.dataset.auth, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(body),
            });
            location.replace('site.html');
        } catch (error) {
            showError(error instanceof TypeError ? 'Não foi possível conectar ao servidor.' : error.message);
        } finally {
            submit.disabled = false;
        }
    });
}

if (sessionPanel) {
    const logout = sessionPanel.querySelector('[data-auth-logout]');
    logout.addEventListener('click', async () => {
        logout.disabled = true;
        showError('');
        try {
            await request('sair', { method: 'POST' });
            showSession(null);
        } catch {
            showError('Não foi possível sair. Tente novamente.');
        } finally {
            logout.disabled = false;
        }
    });
}

request('sessao').then(showSession).catch(() => {});

window.addEventListener('pageshow', (event) => {
    if (event.persisted) request('sessao').then(showSession).catch(() => {});
});
