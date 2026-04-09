const STORAGE_KEY = 'life_tracker_v2';

let state = {
    currentView: 'home',
    currentUser: 'Biswajith',
    logs: [],
    habits: [
        { id: 101, name: 'Sleep', time: '23:55', freq: 'Everyday', streak: 0, completed: false },
        { id: 102, name: 'Trade', time: '20:00', freq: 'Everyday', streak: 0, completed: false }
    ],
    input: { type: 'Expense', amount: 0, category: 'Salary', desc: '' },
    isLoggedIn: false
};

// --- STARTUP ---
document.addEventListener('DOMContentLoaded', () => {
    try {
        const saved = localStorage.getItem(STORAGE_KEY);
        if (saved) state = { ...state, ...JSON.parse(saved) };

        checkAuth();
        setupAuthUI();
        setupModal();
        if(state.isLoggedIn) switchView('home');
    } catch (e) {
        console.error("Boot Error:", e);
    }
});

function checkAuth() {
    const auth = document.getElementById('auth-screen');
    const app = document.getElementById('app-container');
    
    if(!state.isLoggedIn) {
        auth.classList.remove('hidden');
        app.classList.add('hidden');
    } else {
        auth.classList.add('hidden');
        app.classList.remove('hidden');
    }
}

function setupAuthUI() {
    // Switch between forms
    document.getElementById('go-to-signup').onclick = () => {
        document.getElementById('login-form').classList.add('hidden');
        document.getElementById('signup-form').classList.remove('hidden');
    };
    document.getElementById('go-to-login').onclick = () => {
        document.getElementById('signup-form').classList.add('hidden');
        document.getElementById('login-form').classList.remove('hidden');
    };

    // Submits
    document.getElementById('login-submit').onclick = () => {
        const user = document.getElementById('login-username').value;
        const pass = document.getElementById('login-password').value;
        
        if(user && pass) {
            state.isLoggedIn = true;
            state.currentUser = user;
            saveData();
            checkAuth();
            switchView('home');
        } else alert("Please enter credentials");
    };

    document.getElementById('signup-submit').onclick = () => {
        const user = document.getElementById('signup-username').value;
        const pass = document.getElementById('signup-password').value;
        if(user && pass) {
            alert("Account created successfully! Please Log In.");
            document.getElementById('go-to-login').click();
        } else alert("Fill in all fields");
    };
}

function saveData() { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }

// --- VIEWS ---
function switchView(view) {
    if(!state.isLoggedIn) return;
    state.currentView = view;
    
    // Update Nav Buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.toggle('active', btn.getAttribute('onclick').includes(`'${view}'`));
    });

    const main = document.getElementById('main-view');
    main.innerHTML = `<div class="fade-in"></div>`;
    const content = main.querySelector('.fade-in');

    if (view === 'home') renderHome(main);
    else {
        // Render View Header
        const header = document.createElement('header');
        header.className = 'app-header';
        header.innerHTML = `
            <div data-view="home" onclick="switchView('home')" style="cursor:pointer; color: white;"><i class="fa-solid fa-arrow-left"></i></div>
            <h2 style="font-family:'Outfit'; text-transform:uppercase; font-size:1.1rem; letter-spacing:1px;">${view}</h2>
            <div class="profile-img" style="width:35px; height:35px;">${state.currentUser.charAt(0)}</div>
        `;
        content.appendChild(header);

        if (view === 'analytics') renderAnalytics(content);
        else if (view === 'habits') renderHabits(content);
        else if (view === 'profile') renderProfile(content);
    }
}

function renderHome(container) {
    container.innerHTML = `
        <div class="fade-in">
            <header class="app-header">
                <div class="welcome-section">
                    <p>Welcome back,</p>
                    <h1>${state.currentUser}</h1>
                </div>
                <div class="profile-img">${state.currentUser.charAt(0)}</div>
            </header>

            <div class="quote-card glass"><i class="fa-solid fa-lightbulb"></i><p>"Small steps today, giant leaps tomorrow."</p></div>

            <div class="balance-card">
                <p class="balance-label">Total Balance</p>
                <p class="balance-value">₹${calculateTotal().toLocaleString()}</p>
                <div class="summary-row">
                    <div class="sum-box income"><i class="fa-solid fa-arrow-trend-up"></i><div><p class="sum-label">Income</p><p class="sum-value">₹${calculateByType('Income').toLocaleString()}</p></div></div>
                    <div class="sum-box expense"><i class="fa-solid fa-arrow-trend-down"></i><div><p class="sum-label">Expense</p><p class="sum-value">₹${calculateByType('Expense').toLocaleString()}</p></div></div>
                </div>
            </div>

            <div class="logs-section">
                <div class="section-header"><h2>Recent Log Book</h2><i class="fa-solid fa-pen-to-square"></i></div>
                ${state.logs.length ? state.logs.map(log => `
                    <div class="log-item glass">
                        <div class="log-icon ${log.type.toLowerCase()}"><i class="fa-solid fa-${log.type === 'Income' ? 'arrow-trend-up' : 'arrow-trend-down'}"></i></div>
                        <div class="log-info"><p class="log-title">${log.title}</p><p class="log-cat">${log.cat}</p></div>
                        <div class="log-amount ${log.type.toLowerCase()}">₹${log.amount}</div>
                    </div>
                `).join('') : '<p style="text-align:center; color:#555; padding: 20px;">No trades logged yet.</p>'}
            </div>

            <div style="padding: 20px;">
                <a href="app-release.apk" download style="text-decoration: none;">
                    <div class="glass" style="padding: 20px; display: flex; align-items: center; gap: 15px; border-color: rgba(0, 255, 208, 0.2);">
                        <div class="log-icon income"><i class="fa-brands fa-android"></i></div>
                        <div><p style="font-weight: 700;">Mobile Ready</p><p style="font-size: 0.75rem; color: #666;">v1.0.0 Stable Release</p></div>
                        <i class="fa-solid fa-chevron-right" style="margin-left: auto;"></i>
                    </div>
                </a>
            </div>
        </div>
    `;
}

function renderHabits(container) {
    container.innerHTML += `<div style="padding: 20px;"> ${state.habits.map(h => `
        <div class="log-item glass" onclick="toggleHabit(${h.id})" style="cursor:pointer;">
            <div class="log-icon ${h.completed ? 'income' : 'expense'}" style="border: 2px solid ${h.completed ? '#00ffd0' : '#444'}; background: transparent;">
                ${h.completed ? '<i class="fa-solid fa-check"></i>' : ''}
            </div>
            <div class="log-info"><p class="log-title">${h.name}</p><p class="log-cat">${h.time} | ${h.freq}</p></div>
            <div class="log-amount income"><i class="fa-solid fa-fire"></i> ${h.streak}</div>
        </div>
    `).join('')} </div>`;
}

function renderAnalytics(container) {
    container.innerHTML += `
        <div style="padding: 20px;">
            <div class="glass" style="padding: 20px; margin-bottom: 25px; border-color: var(--accent-magenta);">
                <div style="display:flex; justify-content:space-between; align-items:center;">
                    <div><h3>Finance Intelligence</h3><p style="font-size: 0.75rem; color:#666;">Monthly Performance Breakdown</p></div>
                    <div class="log-icon income"><i class="fa-solid fa-wand-sparkles"></i></div>
                </div>
            </div>
            <div class="glass" style="height: 300px; padding: 20px;"><canvas id="chart"></canvas></div>
        </div>
    `;
    setTimeout(() => initChart(), 100);
}

function renderProfile(container) {
    container.innerHTML += `
        <div style="padding: 20px; text-align: center;">
            <div class="profile-img" style="width:100px; height:100px; font-size: 2.5rem; margin: 0 auto 20px;">${state.currentUser.charAt(0)}</div>
            <h2 style="font-family:'Outfit'; font-size: 1.8rem;">${state.currentUser}</h2>
            <p style="color: #666; margin-bottom: 40px;">Member since 2026</p>
            <button class="primary-btn" style="background: #ff4d6d; color: white;" onclick="logout()">SIGN OUT</button>
        </div>
    `;
}

// --- LOGIC ---
function logout() { state.isLoggedIn = false; saveData(); location.reload(); }
function toggleHabit(id) {
    const h = state.habits.find(h => h.id === id);
    if(h) {
        h.completed = !h.completed;
        h.streak = h.completed ? h.streak + 1 : Math.max(0, h.streak - 1);
        saveData();
        switchView('habits');
    }
}

function setupModal() {
    document.getElementById('add-log-btn').onclick = () => document.getElementById('modal-overlay').classList.remove('hidden');
    document.getElementById('modal-overlay').onclick = (e) => { if(e.target.id === 'modal-overlay') e.target.classList.add('hidden'); };

    document.querySelectorAll('.chip').forEach(c => c.onclick = () => {
        document.querySelectorAll('.chip').forEach(x => x.classList.remove('active'));
        c.classList.add('active');
        state.input.category = c.textContent;
    });

    document.querySelectorAll('.seg-btn').forEach(b => b.onclick = () => {
        document.querySelectorAll('.seg-btn').forEach(x => x.classList.remove('active'));
        b.classList.add('active');
        state.input.type = b.getAttribute('data-type');
    });

    document.getElementById('save-log-btn').onclick = () => {
        const desc = document.getElementById('desc-input').value;
        const amt = prompt("Amount (₹):", "0");
        if(amt) {
            state.logs.unshift({ id: Date.now(), title: desc || 'Item', cat: state.input.category || 'General', amount: parseFloat(amt), type: state.input.type || 'Expense' });
            saveData();
            document.getElementById('modal-overlay').classList.add('hidden');
            switchView('home');
        }
    };
}

function calculateTotal() { return state.logs.reduce((a, l) => l.type === 'Income' ? a + l.amount : a - l.amount, 0); }
function calculateByType(t) { return state.logs.filter(l => l.type === t).reduce((a, l) => a + l.amount, 0); }

function initChart() {
    const ctx = document.getElementById('chart')?.getContext('2d');
    if(!ctx) return;
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: ['Income', 'Expense'],
            datasets: [{ data: [calculateByType('Income'), calculateByType('Expense')], backgroundColor: ['#00ffd0', '#ff4d6d'], borderColor: '#111', borderWidth: 8 }]
        },
        options: { cutout: '80%', plugins: { legend: { display: false } } }
    });
}
