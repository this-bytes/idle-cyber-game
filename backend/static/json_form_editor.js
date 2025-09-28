/**
 * JSON Form Editor - Advanced form-based JSON editing tool
 * Part of Cyberspace Tycoon Backend Admin Tools
 */

class JsonFormEditor {
    constructor(containerId, options = {}) {
        this.container = document.getElementById(containerId);
        this.options = {
            theme: 'cyber',
            showRawJson: true,
            enableValidation: true,
            autoSave: false,
            ...options
        };
        this.data = {};
        this.schema = null;
        this.formElements = new Map();
        this.validationErrors = new Map();
        
        this.init();
    }
    
    init() {
        this.container.innerHTML = this.renderContainer();
        this.bindEvents();
    }
    
    renderContainer() {
        return `
            <div class="json-form-editor ${this.options.theme}">
                <div class="editor-header">
                    <div class="editor-title">
                        <h3>🛠️ Advanced JSON Form Editor</h3>
                        <div class="editor-status" id="editor-status">Ready</div>
                    </div>
                    <div class="editor-controls">
                        <button class="btn btn-secondary" id="view-raw-json">📄 Raw JSON</button>
                        <button class="btn btn-primary" id="validate-data">✅ Validate</button>
                        <button class="btn btn-success" id="save-data">💾 Save</button>
                    </div>
                </div>
                
                <div class="editor-body">
                    <div class="form-panel" id="form-panel">
                        <div class="loading-state">
                            <div class="cyber-loader"></div>
                            <p>Initializing form editor...</p>
                        </div>
                    </div>
                    
                    <div class="raw-json-panel" id="raw-json-panel" style="display: none;">
                        <div class="panel-header">
                            <h4>📄 Raw JSON Data</h4>
                            <button class="btn btn-sm" id="format-json">🎨 Format</button>
                        </div>
                        <textarea id="raw-json-editor" class="json-textarea"></textarea>
                        <div class="json-actions">
                            <button class="btn btn-secondary" id="import-json">📥 Import</button>
                            <button class="btn btn-secondary" id="export-json">📤 Export</button>
                        </div>
                    </div>
                </div>
                
                <div class="editor-footer">
                    <div class="validation-panel" id="validation-panel"></div>
                </div>
            </div>
        `;
    }
    
    bindEvents() {
        // View toggle
        document.getElementById('view-raw-json').addEventListener('click', () => {
            this.toggleView();
        });
        
        // Data operations
        document.getElementById('validate-data').addEventListener('click', () => {
            this.validateData();
        });
        
        document.getElementById('save-data').addEventListener('click', () => {
            this.saveData();
        });
        
        // JSON operations
        document.getElementById('format-json').addEventListener('click', () => {
            this.formatRawJson();
        });
        
        document.getElementById('import-json').addEventListener('click', () => {
            this.importFromRawJson();
        });
        
        document.getElementById('export-json').addEventListener('click', () => {
            this.exportToRawJson();
        });
    }
    
    loadData(data, schema = null) {
        this.data = JSON.parse(JSON.stringify(data)); // Deep clone
        this.schema = schema;
        this.renderForm();
        this.updateStatus('Data loaded successfully', 'success');
    }
    
    renderForm() {
        const formPanel = document.getElementById('form-panel');
        formPanel.innerHTML = this.generateFormHTML(this.data);
        this.bindFormEvents();
    }
    
    generateFormHTML(data, path = '') {
        if (typeof data !== 'object' || data === null) {
            return this.renderPrimitiveField(data, path);
        }
        
        if (Array.isArray(data)) {
            return this.renderArrayField(data, path);
        }
        
        return this.renderObjectField(data, path);
    }
    
    renderObjectField(obj, path) {
        const fieldId = this.getFieldId(path);
        let html = `<div class="form-group object-field" data-path="${path}">`;
        
        if (path) {
            html += `<label class="field-label">${this.getFieldLabel(path)}</label>`;
        }
        
        html += `<div class="object-container">`;
        
        for (const [key, value] of Object.entries(obj)) {
            const fieldPath = path ? `${path}.${key}` : key;
            html += `
                <div class="form-field" data-key="${key}">
                    <div class="field-header">
                        <label class="field-name">${key}</label>
                        <div class="field-controls">
                            <button class="btn-icon btn-edit" title="Edit key name">✏️</button>
                            <button class="btn-icon btn-delete" title="Delete field">🗑️</button>
                        </div>
                    </div>
                    ${this.generateFormHTML(value, fieldPath)}
                </div>
            `;
        }
        
        html += `
            <div class="add-field-container">
                <button class="btn btn-secondary add-field-btn" data-path="${path}">
                    ➕ Add Field
                </button>
            </div>
        </div>
        </div>`;
        
        return html;
    }
    
    renderArrayField(arr, path) {
        let html = `<div class="form-group array-field" data-path="${path}">`;
        html += `<label class="field-label">${this.getFieldLabel(path)} (Array)</label>`;
        html += `<div class="array-container">`;
        
        arr.forEach((item, index) => {
            const itemPath = `${path}[${index}]`;
            html += `
                <div class="array-item" data-index="${index}">
                    <div class="item-header">
                        <span class="item-index">[${index}]</span>
                        <div class="item-controls">
                            <button class="btn-icon btn-move-up" title="Move up">⬆️</button>
                            <button class="btn-icon btn-move-down" title="Move down">⬇️</button>
                            <button class="btn-icon btn-delete" title="Delete item">🗑️</button>
                        </div>
                    </div>
                    ${this.generateFormHTML(item, itemPath)}
                </div>
            `;
        });
        
        html += `
            <div class="add-item-container">
                <button class="btn btn-secondary add-item-btn" data-path="${path}">
                    ➕ Add Item
                </button>
            </div>
        </div>
        </div>`;
        
        return html;
    }
    
    renderPrimitiveField(value, path) {
        const fieldType = this.detectFieldType(value, path);
        const fieldId = this.getFieldId(path);
        
        let inputHtml = '';
        
        switch (fieldType) {
            case 'boolean':
                inputHtml = `
                    <label class="checkbox-container">
                        <input type="checkbox" id="${fieldId}" data-path="${path}" 
                               ${value ? 'checked' : ''} class="form-checkbox">
                        <span class="checkbox-label">${value ? 'True' : 'False'}</span>
                    </label>
                `;
                break;
                
            case 'number':
                inputHtml = `
                    <input type="number" id="${fieldId}" data-path="${path}" 
                           value="${value}" class="form-input number-input" 
                           step="any">
                `;
                break;
                
            case 'select':
                const options = this.getSelectOptions(path);
                inputHtml = `
                    <select id="${fieldId}" data-path="${path}" class="form-select">
                        ${options.map(opt => 
                            `<option value="${opt.value}" ${opt.value === value ? 'selected' : ''}>
                                ${opt.label}
                            </option>`
                        ).join('')}
                    </select>
                `;
                break;
                
            case 'textarea':
                inputHtml = `
                    <textarea id="${fieldId}" data-path="${path}" 
                              class="form-textarea" rows="3">${value}</textarea>
                `;
                break;
                
            default: // text
                inputHtml = `
                    <input type="text" id="${fieldId}" data-path="${path}" 
                           value="${value}" class="form-input text-input">
                `;
        }
        
        return `
            <div class="form-group primitive-field">
                ${inputHtml}
            </div>
        `;
    }
    
    detectFieldType(value, path) {
        if (typeof value === 'boolean') return 'boolean';
        if (typeof value === 'number') return 'number';
        
        // Check schema for field type hints
        if (this.schema && this.schema.fieldTypes && this.schema.fieldTypes[path]) {
            return this.schema.fieldTypes[path];
        }
        
        // Heuristic detection
        if (typeof value === 'string') {
            if (value.length > 100) return 'textarea';
            if (path.toLowerCase().includes('description')) return 'textarea';
            if (path.toLowerCase().includes('level') || path.toLowerCase().includes('type')) {
                return 'select';
            }
        }
        
        return 'text';
    }
    
    getSelectOptions(path) {
        // Default options based on field name patterns
        if (path.toLowerCase().includes('risklevel') || path.toLowerCase().includes('risk_level')) {
            return [
                { value: 'LOW', label: '🟢 Low Risk' },
                { value: 'MEDIUM', label: '🟡 Medium Risk' },
                { value: 'HIGH', label: '🔴 High Risk' },
                { value: 'CRITICAL', label: '🚨 Critical Risk' }
            ];
        }
        
        if (path.toLowerCase().includes('type')) {
            return [
                { value: 'basic', label: 'Basic' },
                { value: 'advanced', label: 'Advanced' },
                { value: 'expert', label: 'Expert' }
            ];
        }
        
        return [{ value: '', label: 'Select...' }];
    }
    
    bindFormEvents() {
        // Input change handlers
        this.container.querySelectorAll('input, select, textarea').forEach(element => {
            element.addEventListener('input', (e) => {
                this.handleFieldChange(e.target);
            });
            element.addEventListener('change', (e) => {
                this.handleFieldChange(e.target);
            });
        });
        
        // Field control handlers
        this.container.querySelectorAll('.btn-delete').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.deleteField(e.target);
            });
        });
        
        this.container.querySelectorAll('.add-field-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.addField(e.target.dataset.path);
            });
        });
        
        this.container.querySelectorAll('.add-item-btn').forEach(btn => {
            btn.addEventListener('click', (e) => {
                this.addArrayItem(e.target.dataset.path);
            });
        });
    }
    
    handleFieldChange(element) {
        const path = element.dataset.path;
        let value = element.value;
        
        // Type conversion
        if (element.type === 'checkbox') {
            value = element.checked;
        } else if (element.type === 'number') {
            value = parseFloat(value) || 0;
        }
        
        this.setValueAtPath(this.data, path, value);
        this.updateStatus('Data modified', 'info');
        
        if (this.options.autoSave) {
            this.saveData();
        }
    }
    
    setValueAtPath(obj, path, value) {
        const keys = path.split(/[.\[\]]+/).filter(k => k !== '');
        let current = obj;
        
        for (let i = 0; i < keys.length - 1; i++) {
            const key = keys[i];
            if (!(key in current)) {
                current[key] = isNaN(keys[i + 1]) ? {} : [];
            }
            current = current[key];
        }
        
        current[keys[keys.length - 1]] = value;
    }
    
    getFieldId(path) {
        return `field_${path.replace(/[.\[\]]/g, '_')}`;
    }
    
    getFieldLabel(path) {
        return path.split(/[.\[\]]/).pop().replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
    }
    
    toggleView() {
        const formPanel = document.getElementById('form-panel');
        const jsonPanel = document.getElementById('raw-json-panel');
        const toggleBtn = document.getElementById('view-raw-json');
        
        if (formPanel.style.display === 'none') {
            formPanel.style.display = 'block';
            jsonPanel.style.display = 'none';
            toggleBtn.textContent = '📄 Raw JSON';
        } else {
            formPanel.style.display = 'none';
            jsonPanel.style.display = 'block';
            toggleBtn.textContent = '📝 Form View';
            this.exportToRawJson();
        }
    }
    
    validateData() {
        this.validationErrors.clear();
        
        // Basic validation
        const errors = this.performValidation(this.data);
        
        this.displayValidationResults(errors);
        this.updateStatus(
            errors.length === 0 ? 'Validation passed' : `${errors.length} validation errors`,
            errors.length === 0 ? 'success' : 'error'
        );
        
        return errors.length === 0;
    }
    
    performValidation(data, path = '') {
        const errors = [];
        
        // Custom validation rules based on data structure
        if (Array.isArray(data)) {
            data.forEach((item, index) => {
                const itemPath = `${path}[${index}]`;
                errors.push(...this.performValidation(item, itemPath));
            });
        } else if (typeof data === 'object' && data !== null) {
            // Validate contract structure
            if (path === '' && Array.isArray(this.data)) {
                data.forEach((contract, index) => {
                    if (!contract.id) {
                        errors.push(`Contract ${index}: Missing required field 'id'`);
                    }
                    if (!contract.clientName) {
                        errors.push(`Contract ${index}: Missing required field 'clientName'`);
                    }
                    if (typeof contract.baseBudget !== 'number' || contract.baseBudget <= 0) {
                        errors.push(`Contract ${index}: baseBudget must be a positive number`);
                    }
                });
            }
            
            for (const [key, value] of Object.entries(data)) {
                const fieldPath = path ? `${path}.${key}` : key;
                errors.push(...this.performValidation(value, fieldPath));
            }
        }
        
        return errors;
    }
    
    displayValidationResults(errors) {
        const panel = document.getElementById('validation-panel');
        
        if (errors.length === 0) {
            panel.innerHTML = `
                <div class="validation-success">
                    ✅ All validation checks passed!
                </div>
            `;
        } else {
            panel.innerHTML = `
                <div class="validation-errors">
                    <h4>❌ Validation Errors (${errors.length})</h4>
                    <ul>
                        ${errors.map(error => `<li>${error}</li>`).join('')}
                    </ul>
                </div>
            `;
        }
    }
    
    exportToRawJson() {
        const textarea = document.getElementById('raw-json-editor');
        textarea.value = JSON.stringify(this.data, null, 2);
    }
    
    importFromRawJson() {
        const textarea = document.getElementById('raw-json-editor');
        try {
            this.data = JSON.parse(textarea.value);
            this.renderForm();
            this.updateStatus('JSON imported successfully', 'success');
        } catch (error) {
            this.updateStatus(`JSON import failed: ${error.message}`, 'error');
        }
    }
    
    formatRawJson() {
        const textarea = document.getElementById('raw-json-editor');
        try {
            const parsed = JSON.parse(textarea.value);
            textarea.value = JSON.stringify(parsed, null, 2);
            this.updateStatus('JSON formatted', 'success');
        } catch (error) {
            this.updateStatus(`Format failed: ${error.message}`, 'error');
        }
    }
    
    saveData() {
        if (this.options.onSave) {
            return this.options.onSave(this.data);
        }
        
        this.updateStatus('Save functionality not configured', 'warning');
    }
    
    updateStatus(message, type = 'info') {
        const status = document.getElementById('editor-status');
        status.textContent = message;
        status.className = `editor-status ${type}`;
        
        // Auto-clear after 3 seconds for non-error messages
        if (type !== 'error') {
            setTimeout(() => {
                status.textContent = 'Ready';
                status.className = 'editor-status';
            }, 3000);
        }
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = JsonFormEditor;
}