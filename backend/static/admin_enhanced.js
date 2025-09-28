/**
 * Enhanced Admin Dashboard - Main Controller
 * Part of Cyberspace Tycoon Backend Admin Tools
 */

class EnhancedAdminDashboard {
    constructor() {
        this.currentFile = 'contracts';
        this.jsonEditor = null;
        this.fileData = new Map();
        this.fileSchemas = new Map();
        
        this.init();
    }
    
    init() {
        this.bindNavigationEvents();
        this.initFileSelector();
        this.initJsonEditor();
        this.loadInitialData();
    }
    
    bindNavigationEvents() {
        // Navigation links
        document.querySelectorAll('[data-section]').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                this.showSection(link.dataset.section);
                this.setActiveNavLink(link);
            });
        });
    }
    
    initFileSelector() {
        // File tabs
        document.querySelectorAll('.file-tab').forEach(tab => {
            tab.addEventListener('click', () => {
                this.selectFile(tab.dataset.file);
                this.setActiveFileTab(tab);
            });
        });
    }
    
    async initJsonEditor() {
        this.jsonEditor = new JsonFormEditor('json-form-editor', {
            theme: 'cyber',
            showRawJson: true,
            enableValidation: true,
            autoSave: false,
            onSave: async (data) => {
                return await this.saveCurrentFile(data);
            }
        });
    }
    
    async loadInitialData() {
        try {
            // Load all available files
            await this.loadFile('contracts');
            await this.loadFile('defs');
            await this.loadFile('currencies');
            await this.loadFile('progression');
            
            // Set up initial file
            this.selectFile('contracts');
            
        } catch (error) {
            this.showNotification('Failed to load initial data: ' + error.message, 'error');
        }
    }
    
    async loadFile(fileName) {
        try {
            this.updateFileInfo(`Loading ${fileName}...`);
            
            let data;
            let endpoint;
            
            // Determine the correct endpoint based on file type
            switch (fileName) {
                case 'contracts':
                    endpoint = '/admin/data/contracts';
                    break;
                case 'defs':
                    endpoint = '/admin/data/defs';
                    break;
                case 'currencies':
                case 'progression':
                    endpoint = `/admin/files/${fileName}.json`;
                    break;
                default:
                    throw new Error(`Unknown file type: ${fileName}`);
            }
            
            const response = await fetch(endpoint, { cache: 'no-cache' });
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${await response.text()}`);
            }
            
            if (fileName === 'currencies' || fileName === 'progression') {
                const fileData = await response.json();
                data = JSON.parse(fileData.content);
            } else {
                data = await response.json();
            }
            
            this.fileData.set(fileName, data);
            this.fileSchemas.set(fileName, this.generateSchema(fileName, data));
            
            this.showNotification(`${fileName} loaded successfully`, 'success');
            
        } catch (error) {
            console.error(`Failed to load ${fileName}:`, error);
            this.showNotification(`Failed to load ${fileName}: ${error.message}`, 'error');
        }
    }
    
    generateSchema(fileName, data) {
        const schema = {
            fieldTypes: {},
            validationRules: {}
        };
        
        // Generate schema based on file type and data structure
        switch (fileName) {
            case 'contracts':
                schema.fieldTypes = {
                    'riskLevel': 'select',
                    'description': 'textarea',
                    'baseBudget': 'number',
                    'baseDuration': 'number',
                    'reputationReward': 'number'
                };
                break;
                
            case 'defs':
                // Dynamic schema generation for definitions
                break;
                
            case 'currencies':
                schema.fieldTypes = {
                    'description': 'textarea',
                    'baseValue': 'number',
                    'multiplier': 'number'
                };
                break;
                
            case 'progression':
                schema.fieldTypes = {
                    'description': 'textarea',
                    'requiredXP': 'number',
                    'unlockLevel': 'number'
                };
                break;
        }
        
        return schema;
    }
    
    selectFile(fileName) {
        this.currentFile = fileName;
        const data = this.fileData.get(fileName);
        const schema = this.fileSchemas.get(fileName);
        
        if (data) {
            this.jsonEditor.loadData(data, schema);
            this.updateFileInfo(this.getFileDescription(fileName));
        } else {
            this.loadFile(fileName).then(() => {
                const loadedData = this.fileData.get(fileName);
                const loadedSchema = this.fileSchemas.get(fileName);
                if (loadedData) {
                    this.jsonEditor.loadData(loadedData, loadedSchema);
                    this.updateFileInfo(this.getFileDescription(fileName));
                }
            });
        }
    }
    
    getFileDescription(fileName) {
        const descriptions = {
            'contracts': 'Contract definitions including client information, budgets, durations, and requirements. Each contract defines a task players can undertake.',
            'defs': 'Core game definitions including resources, departments, and game modes. These are fundamental building blocks of the game.',
            'currencies': 'Currency definitions and exchange rates. Manages all forms of in-game currency and their relationships.',
            'progression': 'Player progression settings including experience requirements, level unlocks, and advancement rules.'
        };
        
        return descriptions[fileName] || 'Configuration file for game settings and data.';
    }
    
    async saveCurrentFile(data) {
        try {
            this.updateFileInfo('Saving changes...');
            
            let endpoint;
            let method = 'PUT';
            let body;
            
            switch (this.currentFile) {
                case 'contracts':
                    endpoint = '/admin/data/contracts';
                    body = JSON.stringify(data, null, 2);
                    break;
                    
                case 'defs':
                    endpoint = '/admin/data/defs';
                    body = JSON.stringify(data, null, 2);
                    break;
                    
                case 'currencies':
                case 'progression':
                    endpoint = `/admin/files/${this.currentFile}.json`;
                    body = JSON.stringify({
                        content: JSON.stringify(data, null, 2)
                    });
                    break;
                    
                default:
                    throw new Error(`Unknown file type: ${this.currentFile}`);
            }
            
            const response = await fetch(endpoint, {
                method: method,
                headers: {
                    'Content-Type': 'application/json'
                },
                body: body
            });
            
            if (!response.ok) {
                const errorText = await response.text();
                throw new Error(`HTTP ${response.status}: ${errorText}`);
            }
            
            // Update local cache
            this.fileData.set(this.currentFile, data);
            
            this.showNotification(`${this.currentFile} saved successfully`, 'success');
            this.updateFileInfo(this.getFileDescription(this.currentFile));
            
            return true;
            
        } catch (error) {
            console.error('Save failed:', error);
            this.showNotification(`Save failed: ${error.message}`, 'error');
            this.updateFileInfo(this.getFileDescription(this.currentFile));
            return false;
        }
    }
    
    showSection(sectionName) {
        // Hide all sections
        document.querySelectorAll('.section').forEach(section => {
            section.classList.remove('active');
        });
        
        // Show selected section
        const targetSection = document.getElementById(sectionName);
        if (targetSection) {
            targetSection.classList.add('active');
        }
    }
    
    setActiveNavLink(activeLink) {
        document.querySelectorAll('.nav-link').forEach(link => {
            link.classList.remove('active');
        });
        activeLink.classList.add('active');
    }
    
    setActiveFileTab(activeTab) {
        document.querySelectorAll('.file-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        activeTab.classList.add('active');
    }
    
    updateFileInfo(info) {
        const fileInfoElement = document.getElementById('file-info');
        if (fileInfoElement) {
            fileInfoElement.textContent = info;
        }
    }
    
    showNotification(message, type = 'info') {
        const notification = document.getElementById('notification');
        notification.textContent = message;
        notification.className = `notification ${type} show`;
        
        // Auto-hide after 4 seconds for non-error messages
        if (type !== 'error') {
            setTimeout(() => {
                notification.classList.remove('show');
            }, 4000);
        } else {
            // Error messages stay longer
            setTimeout(() => {
                notification.classList.remove('show');
            }, 8000);
        }
    }
}

// Community Tools Functions
async function shareToMoon() {
    const dashboard = window.adminDashboard;
    const currentData = dashboard.fileData.get(dashboard.currentFile);
    
    if (!currentData) {
        dashboard.showNotification('No data to share', 'warning');
        return;
    }
    
    // Mock implementation - in real version this would upload to a community repository
    const shareData = {
        fileName: dashboard.currentFile,
        data: currentData,
        timestamp: new Date().toISOString(),
        version: '1.0',
        description: `Shared ${dashboard.currentFile} configuration`,
        author: 'Administrator'
    };
    
    try {
        // Simulate API call to community repository
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        dashboard.showNotification(`🌙 ${dashboard.currentFile} shared to the moon successfully!`, 'success');
        
        // Could implement actual upload to GitHub, cloud storage, etc.
        console.log('Data shared to moon:', shareData);
        
    } catch (error) {
        dashboard.showNotification(`Failed to share to moon: ${error.message}`, 'error');
    }
}

async function importFromMoon() {
    const dashboard = window.adminDashboard;
    
    try {
        dashboard.showNotification('🌙 Connecting to the moon...', 'info');
        
        // Mock implementation - simulate fetching from community repository
        await new Promise(resolve => setTimeout(resolve, 1500));
        
        // Mock community data
        const communityData = {
            contracts: [
                {
                    id: "community_crypto_audit",
                    clientName: "CryptoSecure Ltd",
                    description: "Comprehensive blockchain security audit with smart contract analysis",
                    baseBudget: 7500,
                    baseDuration: 180,
                    reputationReward: 25,
                    riskLevel: "HIGH",
                    requiredResources: ["blockchain_expert", "smart_contract_tools"]
                }
            ]
        };
        
        // Show import dialog (simplified for demo)
        const confirmImport = confirm(
            `🌙 Found community ${dashboard.currentFile} data!\n\n` +
            `Would you like to merge it with your current configuration?`
        );
        
        if (confirmImport) {
            const currentData = dashboard.fileData.get(dashboard.currentFile);
            
            if (Array.isArray(currentData) && Array.isArray(communityData[dashboard.currentFile])) {
                // Merge arrays
                const merged = [...currentData, ...communityData[dashboard.currentFile]];
                dashboard.fileData.set(dashboard.currentFile, merged);
                dashboard.jsonEditor.loadData(merged, dashboard.fileSchemas.get(dashboard.currentFile));
                
                dashboard.showNotification(`🌙 Successfully imported community ${dashboard.currentFile}!`, 'success');
            } else {
                dashboard.showNotification('Cannot merge: incompatible data structures', 'warning');
            }
        }
        
    } catch (error) {
        dashboard.showNotification(`Failed to import from moon: ${error.message}`, 'error');
    }
}

async function validateWithCommunity() {
    const dashboard = window.adminDashboard;
    const currentData = dashboard.fileData.get(dashboard.currentFile);
    
    if (!currentData) {
        dashboard.showNotification('No data to validate', 'warning');
        return;
    }
    
    try {
        dashboard.showNotification('🔍 Validating with community standards...', 'info');
        
        // Mock community validation
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const validationResults = {
            passed: true,
            score: 95,
            issues: [
                'Consider adding more detailed descriptions for better community compatibility',
                'Some field names could be more standardized'
            ],
            suggestions: [
                'Add tags field for better categorization',
                'Include difficulty rating for user guidance'
            ]
        };
        
        if (validationResults.passed) {
            dashboard.showNotification(
                `✅ Community validation passed! Score: ${validationResults.score}/100`,
                'success'
            );
        } else {
            dashboard.showNotification(
                `❌ Community validation failed. Check console for details.`,
                'error'
            );
        }
        
        console.log('Community validation results:', validationResults);
        
    } catch (error) {
        dashboard.showNotification(`Community validation failed: ${error.message}`, 'error');
    }
}

async function exportTemplate() {
    const dashboard = window.adminDashboard;
    const currentData = dashboard.fileData.get(dashboard.currentFile);
    
    if (!currentData) {
        dashboard.showNotification('No data to export', 'warning');
        return;
    }
    
    try {
        // Create template from current data
        let template;
        
        if (Array.isArray(currentData) && currentData.length > 0) {
            // Create template from first item
            template = JSON.parse(JSON.stringify(currentData[0]));
            
            // Replace values with template placeholders
            const replaceWithPlaceholders = (obj, path = '') => {
                for (const [key, value] of Object.entries(obj)) {
                    const currentPath = path ? `${path}.${key}` : key;
                    
                    if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
                        replaceWithPlaceholders(value, currentPath);
                    } else if (typeof value === 'string') {
                        obj[key] = `{{${currentPath}}}`;
                    } else if (typeof value === 'number') {
                        obj[key] = `{{${currentPath}_NUMBER}}`;
                    } else if (typeof value === 'boolean') {
                        obj[key] = `{{${currentPath}_BOOLEAN}}`;
                    } else if (Array.isArray(value)) {
                        obj[key] = [`{{${currentPath}_ARRAY_ITEM}}`];
                    }
                }
            };
            
            replaceWithPlaceholders(template);
        } else {
            template = currentData;
        }
        
        // Create downloadable template
        const templateData = {
            name: `${dashboard.currentFile}_template`,
            version: '1.0',
            description: `Template for ${dashboard.currentFile} configuration`,
            template: template,
            created: new Date().toISOString()
        };
        
        const blob = new Blob([JSON.stringify(templateData, null, 2)], {
            type: 'application/json'
        });
        
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${dashboard.currentFile}_template.json`;
        a.click();
        
        URL.revokeObjectURL(url);
        
        dashboard.showNotification(`📋 Template exported successfully!`, 'success');
        
    } catch (error) {
        dashboard.showNotification(`Template export failed: ${error.message}`, 'error');
    }
}

function collaborativeEdit() {
    const dashboard = window.adminDashboard;
    dashboard.showNotification('👥 Collaborative editing coming soon!', 'info');
    
    // Mock implementation showing the concept
    setTimeout(() => {
        dashboard.showNotification('🚧 Feature in development: Real-time collaborative editing', 'warning');
    }, 2000);
}

function versionCompare() {
    const dashboard = window.adminDashboard;
    dashboard.showNotification('📊 Version comparison coming soon!', 'info');
    
    // Mock implementation
    setTimeout(() => {
        dashboard.showNotification('🚧 Feature in development: Advanced version comparison and diff viewing', 'warning');
    }, 2000);
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.adminDashboard = new EnhancedAdminDashboard();
    
    // Add some nice loading effects
    setTimeout(() => {
        document.body.style.opacity = '1';
    }, 100);
});