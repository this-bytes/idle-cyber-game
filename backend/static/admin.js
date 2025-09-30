// Cyberspace Tycoon Admin Dashboard
// Self-contained admin interface without external dependencies

// Global variables
let currentSection = 'dashboard';
let currentFile = null;
let refreshInterval = null;

// Utility functions
async function apiGet(url) {
    const response = await fetch(url, { cache: 'no-cache' });
    if (!response.ok) throw new Error(await response.text());
    return response.json();
}

async function apiPost(url, data) {
    const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    if (!response.ok) throw new Error(await response.text());
    return response.json();
}

async function apiPut(url, data) {
    const response = await fetch(url, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    if (!response.ok) throw new Error(await response.text());
    return response.json();
}

function showNotification(message, type = 'success') {
    // Remove existing notifications
    const existing = document.querySelectorAll('.notification');
    existing.forEach(n => n.remove());
    
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    // Show notification
    setTimeout(() => notification.classList.add('show'), 100);
    
    // Auto-remove after 4 seconds
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 4000);
}

function formatNumber(num) {
    if (num >= 1000000) return (num / 1000000).toFixed(1) + 'M';
    if (num >= 1000) return (num / 1000).toFixed(1) + 'K';
    return Math.round(num).toString();
}

function formatDate(dateString) {
    return new Date(dateString).toLocaleString();
}

// Section management
function showSection(sectionName) {
    // Hide all sections
    document.querySelectorAll('.section').forEach(section => {
        section.classList.remove('active');
    });
    
    // Show selected section
    document.getElementById(sectionName).classList.add('active');
    
    // Update navigation
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });
    document.querySelector(`[data-section="${sectionName}"]`).classList.add('active');
    
    currentSection = sectionName;
    
    // Load section data
    switch (sectionName) {
        case 'dashboard':
            loadDashboard();
            break;
        case 'players':
            loadPlayers();
            break;
        case 'database':
            loadDatabase();
            break;
        case 'files':
            loadFiles();
            break;
        case 'editor':
            loadEditor();
            break;
        case 'achievements':
            loadAchievements();
            break;
        case 'skills':
            loadSkills();
            break;
        case 'specialists':
            loadSpecialists();
            break;
        case 'items':
            loadItems();
            break;
        case 'settings':
            loadSettings();
            break;
    }
}

// Dashboard functions
async function loadDashboard() {
    try {
        const stats = await apiGet('/admin/stats');
        updateDashboardStats(stats.stats);
        updateSystemOverview(stats.stats);
    } catch (error) {
        console.error('Failed to load dashboard:', error);
        showNotification('Failed to load dashboard data', 'error');
    }
}

function updateDashboardStats(stats) {
    document.getElementById('total-players').textContent = stats.players.total;
    document.getElementById('active-players').textContent = stats.players.active_weekly;
    document.getElementById('avg-currency').textContent = '$' + formatNumber(stats.resources.avg_currency);
    document.getElementById('avg-reputation').textContent = formatNumber(stats.resources.avg_reputation);
}

function updateSystemOverview(stats) {
    const container = document.getElementById('system-overview');
    const activityRate = stats.players.activity_rate;
    
    container.innerHTML = `
        <div class="grid grid-2">
            <div>
                <h4>📊 Player Statistics</h4>
                <p><strong>Total Players:</strong> ${stats.players.total}</p>
                <p><strong>Active This Week:</strong> ${stats.players.active_weekly}</p>
                <p><strong>Activity Rate:</strong> ${activityRate}%</p>
                <div style="background: #34495e; height: 20px; border-radius: 10px; overflow: hidden; margin: 10px 0;">
                    <div style="background: ${activityRate > 50 ? '#27ae60' : '#f39c12'}; height: 100%; width: ${activityRate}%; transition: width 0.3s ease;"></div>
                </div>
            </div>
            <div>
                <h4>💰 Resource Averages</h4>
                <p><strong>Currency:</strong> $${formatNumber(stats.resources.avg_currency)}</p>
                <p><strong>Reputation:</strong> ${formatNumber(stats.resources.avg_reputation)}</p>
                <p><strong>Experience:</strong> ${formatNumber(stats.resources.avg_xp)}</p>
                <p><strong>Prestige:</strong> ${formatNumber(stats.resources.avg_prestige)}</p>
            </div>
        </div>
        
        <h4 style="margin-top: 20px;">🏆 Top Players</h4>
        <div class="grid grid-2">
            <div>
                <h5>💰 Richest Players</h5>
                <ul style="list-style: none; padding: 0;">
                    ${stats.leaderboards.top_currency.slice(0, 3).map((player, i) => 
                        `<li style="padding: 5px 0; border-bottom: 1px solid #34495e;">
                            ${i + 1}. ${player.username} - $${formatNumber(player.current_currency)}
                        </li>`
                    ).join('')}
                </ul>
            </div>
            <div>
                <h5>⭐ Most Reputable</h5>
                <ul style="list-style: none; padding: 0;">
                    ${stats.leaderboards.top_reputation.slice(0, 3).map((player, i) => 
                        `<li style="padding: 5px 0; border-bottom: 1px solid #34495e;">
                            ${i + 1}. ${player.username} - ${formatNumber(player.reputation)} REP
                        </li>`
                    ).join('')}
                </ul>
            </div>
        </div>
    `;
}

// Players management
async function loadPlayers() {
    try {
        const response = await apiGet('/admin/players');
        displayPlayers(response.players || []);
    } catch (error) {
        console.error('Failed to load players:', error);
        showNotification('Failed to load players', 'error');
    }
}

function displayPlayers(players) {
    const tbody = document.querySelector('#players-table tbody');
    
    if (players.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">No players found</td></tr>';
        return;
    }
    
    tbody.innerHTML = players.map(player => `
        <tr>
            <td>${player.username}</td>
            <td>$${formatNumber(player.current_currency)}</td>
            <td>${formatNumber(player.reputation)}</td>
            <td>${formatNumber(player.xp || 0)}</td>
            <td>${player.prestige_level}</td>
            <td>${formatDate(player.last_login)}</td>
            <td>
                <button class="btn btn-small" onclick="editPlayer(${player.id})">✏️</button>
                <button class="btn btn-small btn-danger" onclick="deletePlayer(${player.id})">🗑️</button>
            </td>
        </tr>
    `).join('');
}

function refreshPlayers() {
    loadPlayers();
    showNotification('Players refreshed', 'success');
}

// Database management
async function loadDatabase() {
    try {
        const globalState = await apiGet('/admin/global');
        const stats = await apiGet('/admin/stats');
        
        displayGlobalSettings(globalState.global_state);
        displayDatabaseStats(stats.stats);
    } catch (error) {
        console.error('Failed to load database:', error);
        showNotification('Failed to load database data', 'error');
    }
}

function displayGlobalSettings(settings) {
    document.getElementById('base-production-rate').value = settings.base_production_rate;
    document.getElementById('global-multiplier').value = settings.global_multiplier;
    document.getElementById('max-players').value = settings.max_players;
    document.getElementById('maintenance-mode').checked = settings.maintenance_mode;
}

function displayDatabaseStats(stats) {
    const container = document.getElementById('db-stats');
    container.innerHTML = `
        <div class="grid grid-2">
            <div>
                <p><strong>Total Players:</strong> ${stats.players.total}</p>
                <p><strong>Active Players:</strong> ${stats.players.active_weekly}</p>
                <p><strong>Activity Rate:</strong> ${stats.players.activity_rate}%</p>
            </div>
            <div>
                <p><strong>Avg Currency:</strong> $${formatNumber(stats.resources.avg_currency)}</p>
                <p><strong>Avg Reputation:</strong> ${formatNumber(stats.resources.avg_reputation)}</p>
                <p><strong>Avg XP:</strong> ${formatNumber(stats.resources.avg_xp)}</p>
            </div>
        </div>
        <hr style="border-color: #34495e; margin: 20px 0;">
        <p><strong>Last Updated:</strong> ${formatDate(stats.global_state.last_updated)}</p>
        <p><strong>Maintenance Mode:</strong> ${stats.global_state.maintenance_mode ? '🔧 ON' : '✅ OFF'}</p>
    `;
}

// File management
async function loadFiles() {
    try {
        const files = await apiGet('/admin/files');
        displayFiles(files.files);
    } catch (error) {
        console.error('Failed to load files:', error);
        showNotification('Failed to load files', 'error');
    }
}

function displayFiles(files) {
    const container = document.getElementById('file-list');
    
    if (files.length === 0) {
        container.innerHTML = '<div class="text-center text-muted">No files found</div>';
        return;
    }
    
    container.innerHTML = files.map(file => `
        <div class="file-item" onclick="selectFile('${file.path}')">
            <div style="display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <span style="margin-right: 8px;">${file.type === 'json' ? '📄' : '📜'}</span>
                    <strong>${file.name}</strong>
                </div>
                <div>
                    <span style="background: #34495e; padding: 2px 6px; border-radius: 4px; font-size: 0.8em;">
                        ${file.type.toUpperCase()}
                    </span>
                    ${file.editable ? '<span style="background: #27ae60; padding: 2px 6px; border-radius: 4px; font-size: 0.8em; margin-left: 4px;">✏️</span>' : ''}
                </div>
            </div>
            <div style="font-size: 0.8em; color: #8fbcdb; margin-top: 4px;">
                Size: ${(file.size / 1024).toFixed(1)} KB | 
                Modified: ${formatDate(file.modified)}
            </div>
        </div>
    `).join('');
}

async function selectFile(filepath) {
    try {
        currentFile = filepath;
        const fileData = await apiGet(`/admin/files/${filepath}`);
        
        // Clear previous selection
        document.querySelectorAll('.file-item').forEach(item => {
            item.classList.remove('selected');
        });
        
        // Mark current file as selected
        const fileItems = document.querySelectorAll('.file-item');
        fileItems.forEach(item => {
            if (item.textContent.includes(fileData.filename)) {
                item.classList.add('selected');
            }
        });
        
        // Enable/disable save button
        document.getElementById('save-file-btn').disabled = !fileData.editable;
        
        // Update editor
        const container = document.getElementById('file-editor-container');
        
        if (fileData.editable) {
            container.innerHTML = `
                <textarea class="file-editor" id="file-editor" placeholder="File content...">${fileData.content}</textarea>
            `;
        } else {
            container.innerHTML = `
                <div class="text-center text-muted p-4">
                    <div style="font-size: 3em; margin-bottom: 20px;">🔒</div>
                    <p>This file is read-only</p>
                    <pre style="text-align: left; max-height: 300px; overflow-y: auto; background: rgba(26, 31, 58, 0.5); padding: 15px; border-radius: 8px;">${fileData.content}</pre>
                </div>
            `;
        }
        
        showNotification(`Loaded ${fileData.filename}`, 'success');
    } catch (error) {
        console.error('Failed to load file:', error);
        showNotification('Failed to load file', 'error');
    }
}

async function saveCurrentFile() {
    if (!currentFile) return;
    
    const editor = document.getElementById('file-editor');
    if (!editor) return;
    
    try {
        const content = editor.value;
        await apiPut(`/admin/files/${currentFile}`, { content });
        showNotification('File saved successfully', 'success');
    } catch (error) {
        console.error('Failed to save file:', error);
        showNotification('Failed to save file: ' + error.message, 'error');
    }
}

// Level editor
async function loadEditor() {
    try {
        // Load currency data
        const currencyFile = await apiGet('/admin/files/currencies.json');
        const currencyData = JSON.parse(currencyFile.content);
        displayCurrencyEditor(currencyData);
        
        // Load progression data
        const progressionFile = await apiGet('/admin/files/progression.json');
        const progressionData = JSON.parse(progressionFile.content);
        displayProgressionEditor(progressionData);
    } catch (error) {
        console.error('Failed to load editor data:', error);
        showNotification('Failed to load editor data', 'error');
    }
}

function displayCurrencyEditor(currencyData) {
    const container = document.getElementById('currency-editor');
    
    // Check if we have the expected structure
    if (!currencyData || !currencyData.currencies) {
        container.innerHTML = '<div class="text-center text-muted">Invalid currency data structure</div>';
        return;
    }
    
    const currencies = currencyData.currencies;
    let html = '<div class="card" style="margin: 10px 0;">';
    html += '<div class="card-header"><h5>Game Currencies</h5></div>';
    html += '<div style="padding: 15px;">';
    
    // Handle the flat structure where currencies are directly under currencies object
    Object.entries(currencies).forEach(([id, currency]) => {
        if (currency && typeof currency === 'object') {
            html += `
                <div style="margin: 8px 0; padding: 10px; border: 1px solid #34495e; border-radius: 6px; background: rgba(52, 73, 94, 0.3);">
                    <strong>${currency.name || 'Unknown'}</strong> (${currency.symbol || 'N/A'})
                    <br>
                    <small style="color: #8fbcdb;">${currency.description || 'No description'}</small>
                    <br>
                    <span style="background: #3498db; padding: 2px 6px; border-radius: 4px; font-size: 0.8em; margin-top: 4px; display: inline-block; margin-right: 5px;">
                        ID: ${currency.id || id}
                    </span>
                    ${currency.startingAmount ? `<span style="background: #27ae60; padding: 2px 6px; border-radius: 4px; font-size: 0.8em;">Start: ${currency.startingAmount}</span>` : ''}
                </div>
            `;
        }
    });
    
    html += '</div></div>';
    container.innerHTML = html;
}

function displayProgressionEditor(progressionData) {
    const container = document.getElementById('progression-editor');
    const tiers = progressionData.progressionTiers;
    
    let html = '';
    
    Object.entries(tiers).forEach(([id, tier]) => {
        html += `<div class="card" style="margin: 10px 0;">
            <div class="card-header">
                <h5>${tier.name} (Level ${tier.level})</h5>
            </div>
            <div style="padding: 15px;">
                <p style="color: #8fbcdb;">${tier.description}</p>
                <h6>Requirements:</h6>
                <ul style="margin: 5px 0 10px 20px;">
        `;
        
        Object.entries(tier.requirements).forEach(([req, value]) => {
            html += `<li>${req}: ${formatNumber(value)}</li>`;
        });
        
        html += `
                </ul>
                <h6>Bonuses:</h6>
                <ul style="margin: 5px 0 10px 20px;">
        `;
        
        Object.entries(tier.bonuses).forEach(([bonus, value]) => {
            html += `<li>${bonus}: ${value}</li>`;
        });
        
        html += '</ul></div></div>';
    });
    
    container.innerHTML = html;
}

// Achievements
async function loadAchievements() {
    try {
        const achievements = await apiGet('/admin/achievements');
        displayAchievements(achievements.achievements);
    } catch (error) {
        console.error('Failed to load achievements:', error);
        showNotification('Failed to load achievements', 'error');
    }
}

function displayAchievements(achievements) {
    const container = document.getElementById('achievements-list');
    
    if (Object.keys(achievements).length === 0) {
        container.innerHTML = '<div class="text-center text-muted">No achievements found</div>';
        return;
    }
    
    let html = '<div class="grid grid-2">';
    
    Object.entries(achievements).forEach(([id, achievement]) => {
        html += `
            <div class="card" style="margin: 10px;">
                <div style="padding: 20px;">
                    <h4>🏆 ${achievement.name}</h4>
                    <p style="color: #8fbcdb;">${achievement.description}</p>
                    <h6>Rewards:</h6>
                    <ul style="margin: 5px 0 10px 20px;">
        `;
        
        Object.entries(achievement.rewards).forEach(([reward, value]) => {
            html += `<li>${reward}: ${formatNumber(value)}</li>`;
        });
        
        html += `
                    </ul>
                    <small style="color: #8fbcdb;">Trigger: ${achievement.trigger}</small>
                </div>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
}

// Settings
function loadSettings() {
    // Update last updated time
    document.getElementById('last-updated').textContent = new Date().toLocaleString();
}

// Event handlers
document.addEventListener('DOMContentLoaded', function() {
    // Navigation setup
    document.querySelectorAll('[data-section]').forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            showSection(this.dataset.section);
        });
    });
    
    // Global settings form
    document.getElementById('global-settings-form').addEventListener('submit', async function(e) {
        e.preventDefault();
        
        try {
            const formData = {
                base_production_rate: parseFloat(document.getElementById('base-production-rate').value),
                global_multiplier: parseFloat(document.getElementById('global-multiplier').value),
                max_players: parseInt(document.getElementById('max-players').value),
                maintenance_mode: document.getElementById('maintenance-mode').checked
            };
            
            await apiPut('/admin/global', formData);
            showNotification('Global settings saved successfully', 'success');
        } catch (error) {
            console.error('Failed to save settings:', error);
            showNotification('Failed to save settings: ' + error.message, 'error');
        }
    });
    
    // Skills form handler
    const skillForm = document.getElementById('skill-form');
    if (skillForm) {
        skillForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            try {
                const formData = {
                    id: document.getElementById('skill-id').value,
                    name: document.getElementById('skill-name').value,
                    description: document.getElementById('skill-description').value,
                    category: document.getElementById('skill-category').value,
                    maxLevel: parseInt(document.getElementById('skill-max-level').value),
                    baseXpCost: parseInt(document.getElementById('skill-base-xp').value),
                    xpGrowth: parseFloat(document.getElementById('skill-xp-growth').value),
                    prerequisites: [],
                    unlockRequirements: {},
                    effects: {}
                };
                
                if (currentSkillId) {
                    await apiPut(`/api/skills/${currentSkillId}`, formData);
                    showNotification('Skill updated successfully', 'success');
                } else {
                    await apiPost('/api/skills', formData);
                    showNotification('Skill created successfully', 'success');
                }
                
                hideSkillForm();
                loadSkills();
            } catch (error) {
                console.error('Failed to save skill:', error);
                showNotification('Failed to save skill: ' + error.message, 'error');
            }
        });
    }
    
    // Specialists form handler
    const specialistForm = document.getElementById('specialist-form');
    if (specialistForm) {
        specialistForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            try {
                const formData = {
                    specialistType: document.getElementById('specialist-type').value,
                    name: document.getElementById('specialist-name').value,
                    description: document.getElementById('specialist-description').value,
                    efficiency: parseFloat(document.getElementById('specialist-efficiency').value),
                    speed: parseFloat(document.getElementById('specialist-speed').value),
                    trace: parseFloat(document.getElementById('specialist-trace').value),
                    defense: parseFloat(document.getElementById('specialist-defense').value),
                    cost: {},
                    abilities: [],
                    tier: parseInt(document.getElementById('specialist-tier').value)
                };
                
                if (currentSpecialistId) {
                    await apiPut(`/api/specialists/${currentSpecialistId}`, formData);
                    showNotification('Specialist updated successfully', 'success');
                } else {
                    await apiPost('/api/specialists', formData);
                    showNotification('Specialist created successfully', 'success');
                }
                
                hideSpecialistForm();
                loadSpecialists();
            } catch (error) {
                console.error('Failed to save specialist:', error);
                showNotification('Failed to save specialist: ' + error.message, 'error');
            }
        });
    }
    
    // Items form handler
    const itemForm = document.getElementById('item-form');
    if (itemForm) {
        itemForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            try {
                const formData = {
                    itemId: document.getElementById('item-id').value,
                    name: document.getElementById('item-name').value,
                    description: document.getElementById('item-description').value,
                    category: document.getElementById('item-category').value,
                    rarity: document.getElementById('item-rarity').value,
                    cost: {},
                    effects: {},
                    stackable: document.getElementById('item-stackable').checked,
                    consumable: document.getElementById('item-consumable').checked,
                    maxStack: 1
                };
                
                if (currentItemId) {
                    await apiPut(`/api/items/${currentItemId}`, formData);
                    showNotification('Item updated successfully', 'success');
                } else {
                    await apiPost('/api/items', formData);
                    showNotification('Item created successfully', 'success');
                }
                
                hideItemForm();
                loadItems();
            } catch (error) {
                console.error('Failed to save item:', error);
                showNotification('Failed to save item: ' + error.message, 'error');
            }
        });
    }
    
    // Player search
    const playerSearch = document.getElementById('player-search');
    if (playerSearch) {
        playerSearch.addEventListener('input', function() {
            const searchTerm = this.value.toLowerCase();
            const rows = document.querySelectorAll('#players-table tbody tr');
            
            rows.forEach(row => {
                if (row.cells.length > 1) {
                    const username = row.cells[0].textContent.toLowerCase();
                    row.style.display = username.includes(searchTerm) ? '' : 'none';
                }
            });
        });
    }
    
    // Auto-refresh setup
    const autoRefresh = document.getElementById('auto-refresh');
    if (autoRefresh) {
        autoRefresh.addEventListener('change', function() {
            if (this.checked) {
                refreshInterval = setInterval(() => {
                    if (currentSection === 'dashboard') {
                        loadDashboard();
                    }
                }, 30000); // Refresh every 30 seconds
            } else {
                if (refreshInterval) {
                    clearInterval(refreshInterval);
                    refreshInterval = null;
                }
            }
        });
        
        // Start auto-refresh by default
        autoRefresh.dispatchEvent(new Event('change'));
    }
    
    // Initialize dashboard
    showSection('dashboard');
});

// Additional utility functions for player management
function editPlayer(playerId) {
    showNotification('Player editing functionality coming soon!', 'error');
}

function deletePlayer(playerId) {
    if (confirm('Are you sure you want to delete this player?')) {
        showNotification('Player deletion functionality coming soon!', 'error');
    }
}

// ===== SKILLS MANAGEMENT =====

let currentSkillId = null;

async function loadSkills() {
    try {
        const response = await apiGet('/api/skills');
        displaySkills(response.skills);
    } catch (error) {
        console.error('Failed to load skills:', error);
        showNotification('Failed to load skills', 'error');
    }
}

function displaySkills(skills) {
    const container = document.getElementById('skills-list');
    
    if (skills.length === 0) {
        container.innerHTML = '<div class="text-center text-muted">No skills found</div>';
        return;
    }
    
    let html = '<div class="grid grid-2">';
    
    skills.forEach(skill => {
        html += `
            <div class="skill-card">
                <div class="card-title">${skill.name}</div>
                <p style="color: #8fbcdb; margin-bottom: 10px;">${skill.description}</p>
                <div class="card-stats">
                    <span class="stat-badge">Category: ${skill.category}</span>
                    <span class="stat-badge">Max Level: ${skill.maxLevel}</span>
                    <span class="stat-badge">Base XP: ${skill.baseXpCost}</span>
                </div>
                <div class="card-actions">
                    <button class="btn btn-small" onclick="editSkill('${skill.id}')">✏️ Edit</button>
                    <button class="btn btn-small btn-danger" onclick="deleteSkill('${skill.id}')">🗑️ Delete</button>
                </div>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
}

function showCreateSkillForm() {
    currentSkillId = null;
    document.getElementById('skill-form-title').textContent = 'Create New Skill';
    document.getElementById('skill-form').reset();
    document.getElementById('skill-id').disabled = false;
    document.getElementById('skill-form-modal').style.display = 'flex';
}

async function editSkill(skillId) {
    try {
        const response = await apiGet(`/api/skills/${skillId}`);
        const skill = response.skill;
        
        currentSkillId = skillId;
        document.getElementById('skill-form-title').textContent = 'Edit Skill';
        
        // Populate form
        document.getElementById('skill-id').value = skill.id;
        document.getElementById('skill-id').disabled = true;
        document.getElementById('skill-name').value = skill.name;
        document.getElementById('skill-description').value = skill.description;
        document.getElementById('skill-category').value = skill.category;
        document.getElementById('skill-max-level').value = skill.maxLevel;
        document.getElementById('skill-base-xp').value = skill.baseXpCost;
        document.getElementById('skill-xp-growth').value = skill.xpGrowth;
        
        document.getElementById('skill-form-modal').style.display = 'flex';
    } catch (error) {
        console.error('Failed to load skill:', error);
        showNotification('Failed to load skill', 'error');
    }
}

function hideSkillForm() {
    document.getElementById('skill-form-modal').style.display = 'none';
}

async function deleteSkill(skillId) {
    if (confirm('Are you sure you want to delete this skill?')) {
        try {
            await fetch(`/api/skills/${skillId}`, { method: 'DELETE' });
            showNotification('Skill deleted successfully', 'success');
            loadSkills();
        } catch (error) {
            console.error('Failed to delete skill:', error);
            showNotification('Failed to delete skill', 'error');
        }
    }
}

// ===== SPECIALISTS MANAGEMENT =====

let currentSpecialistId = null;

async function loadSpecialists() {
    try {
        const response = await apiGet('/api/specialists');
        displaySpecialists(response.specialists);
    } catch (error) {
        console.error('Failed to load specialists:', error);
        showNotification('Failed to load specialists', 'error');
    }
}

function displaySpecialists(specialists) {
    const container = document.getElementById('specialists-list');
    
    if (specialists.length === 0) {
        container.innerHTML = '<div class="text-center text-muted">No specialists found</div>';
        return;
    }
    
    let html = '<div class="grid grid-2">';
    
    specialists.forEach(specialist => {
        html += `
            <div class="specialist-card">
                <div class="card-title">${specialist.name}</div>
                <p style="color: #8fbcdb; margin-bottom: 10px;">${specialist.description}</p>
                <div class="card-stats">
                    <span class="stat-badge">Type: ${specialist.specialistType}</span>
                    <span class="stat-badge">Tier: ${specialist.tier}</span>
                    <span class="stat-badge">Efficiency: ${specialist.efficiency}x</span>
                    <span class="stat-badge">Speed: ${specialist.speed}x</span>
                </div>
                <div class="card-actions">
                    <button class="btn btn-small" onclick="editSpecialist(${specialist.id})">✏️ Edit</button>
                    <button class="btn btn-small btn-danger" onclick="deleteSpecialist(${specialist.id})">🗑️ Delete</button>
                </div>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
}

function showCreateSpecialistForm() {
    currentSpecialistId = null;
    document.getElementById('specialist-form-title').textContent = 'Create New Specialist';
    document.getElementById('specialist-form').reset();
    document.getElementById('specialist-form-modal').style.display = 'flex';
}

async function editSpecialist(specialistId) {
    try {
        const response = await apiGet(`/api/specialists/${specialistId}`);
        const specialist = response.specialist;
        
        currentSpecialistId = specialistId;
        document.getElementById('specialist-form-title').textContent = 'Edit Specialist';
        
        // Populate form
        document.getElementById('specialist-type').value = specialist.specialistType;
        document.getElementById('specialist-name').value = specialist.name;
        document.getElementById('specialist-description').value = specialist.description;
        document.getElementById('specialist-efficiency').value = specialist.efficiency;
        document.getElementById('specialist-speed').value = specialist.speed;
        document.getElementById('specialist-trace').value = specialist.trace;
        document.getElementById('specialist-defense').value = specialist.defense;
        document.getElementById('specialist-tier').value = specialist.tier;
        
        document.getElementById('specialist-form-modal').style.display = 'flex';
    } catch (error) {
        console.error('Failed to load specialist:', error);
        showNotification('Failed to load specialist', 'error');
    }
}

function hideSpecialistForm() {
    document.getElementById('specialist-form-modal').style.display = 'none';
}

async function deleteSpecialist(specialistId) {
    if (confirm('Are you sure you want to delete this specialist?')) {
        try {
            await fetch(`/api/specialists/${specialistId}`, { method: 'DELETE' });
            showNotification('Specialist deleted successfully', 'success');
            loadSpecialists();
        } catch (error) {
            console.error('Failed to delete specialist:', error);
            showNotification('Failed to delete specialist', 'error');
        }
    }
}

// ===== ITEMS MANAGEMENT =====

let currentItemId = null;

async function loadItems() {
    try {
        const response = await apiGet('/api/items');
        displayItems(response.items);
    } catch (error) {
        console.error('Failed to load items:', error);
        showNotification('Failed to load items', 'error');
    }
}

function displayItems(items) {
    const container = document.getElementById('items-list');
    
    if (items.length === 0) {
        container.innerHTML = '<div class="text-center text-muted">No items found</div>';
        return;
    }
    
    let html = '<div class="grid grid-2">';
    
    items.forEach(item => {
        const rarityColors = {
            common: '#8fbcdb',
            uncommon: '#27ae60',
            rare: '#3498db',
            epic: '#9b59b6',
            legendary: '#f39c12'
        };
        
        html += `
            <div class="item-card">
                <div class="card-title" style="color: ${rarityColors[item.rarity] || '#8fbcdb'}">${item.name}</div>
                <p style="color: #8fbcdb; margin-bottom: 10px;">${item.description}</p>
                <div class="card-stats">
                    <span class="stat-badge">Category: ${item.category}</span>
                    <span class="stat-badge" style="color: ${rarityColors[item.rarity] || '#8fbcdb'}">Rarity: ${item.rarity}</span>
                    <span class="stat-badge">Stackable: ${item.stackable ? 'Yes' : 'No'}</span>
                </div>
                <div class="card-actions">
                    <button class="btn btn-small" onclick="editItem(${item.id})">✏️ Edit</button>
                    <button class="btn btn-small btn-danger" onclick="deleteItem(${item.id})">🗑️ Delete</button>
                </div>
            </div>
        `;
    });
    
    html += '</div>';
    container.innerHTML = html;
}

function showCreateItemForm() {
    currentItemId = null;
    document.getElementById('item-form-title').textContent = 'Create New Item';
    document.getElementById('item-form').reset();
    document.getElementById('item-form-modal').style.display = 'flex';
}

async function editItem(itemId) {
    try {
        const response = await apiGet(`/api/items/${itemId}`);
        const item = response.item;
        
        currentItemId = itemId;
        document.getElementById('item-form-title').textContent = 'Edit Item';
        
        // Populate form
        document.getElementById('item-id').value = item.itemId;
        document.getElementById('item-name').value = item.name;
        document.getElementById('item-description').value = item.description;
        document.getElementById('item-category').value = item.category;
        document.getElementById('item-rarity').value = item.rarity;
        document.getElementById('item-stackable').checked = item.stackable;
        document.getElementById('item-consumable').checked = item.consumable;
        
        document.getElementById('item-form-modal').style.display = 'flex';
    } catch (error) {
        console.error('Failed to load item:', error);
        showNotification('Failed to load item', 'error');
    }
}

function hideItemForm() {
    document.getElementById('item-form-modal').style.display = 'none';
}

async function deleteItem(itemId) {
    if (confirm('Are you sure you want to delete this item?')) {
        try {
            await fetch(`/api/items/${itemId}`, { method: 'DELETE' });
            showNotification('Item deleted successfully', 'success');
            loadItems();
        } catch (error) {
            console.error('Failed to delete item:', error);
            showNotification('Failed to delete item', 'error');
        }
    }
}
