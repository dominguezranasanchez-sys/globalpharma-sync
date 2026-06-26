// =========================================
// EVENTOS DE LA UI INDEPENDIENTES
// =========================================

const logoImg = document.getElementById('main-logo');
if (logoImg) {
    logoImg.addEventListener('error', function() {
        this.classList.add('d-none');
    });
}

// =========================================
// CONFIGURACIÓN DE SERVIDOR (CONEXIÓN LOCAL)
// =========================================
const API_BASE_URL = 'http://localhost:5000/api';

// =========================================
// BASE DE DATOS Y ESTADOS
// =========================================
let realDatabase = {
    sucursales: [], empleados: [], clientes: [],
    productos: [], unidades: [], ventas: [],
    traspasos: [], devoluciones: []
};

async function cargarCatalogos() {
    try {
        const respuesta = await fetch(`${API_BASE_URL}/catalogos`);
        if (respuesta.ok) {
            const datos = await respuesta.json();
            realDatabase = { ...realDatabase, ...datos };
            systemStructure.forEach(mod => mod.submodules.forEach(sub => {
                sub.fields.forEach(f => {
                    if(f.type === 'fk' && f.dsKey) f.dataSource = realDatabase[f.dsKey];
                });
            }));
        }
    } catch (error) {
        console.error("Failed to connect to Flask server.", error);
    }
}

// =========================================
// ESTRUCTURA DEL SISTEMA
// =========================================
const systemStructure = [
    {
        title: "1. BASE CATALOGS",
        submodules: [
            { 
                title: "1.1 BRANCH", tableName: "SUCURSAL", pks: ["id_sucursal"],
                fields: [
                    { id: "id_sucursal", label: "Branch ID", type: "text" },
                    { id: "nombre", label: "Branch Name", type: "text" },
                    { id: "direccion", label: "Physical Address", type: "text" },
                    { id: "region", label: "City", type: "text" },
                    { id: "pais", label: "Country", type: "select", options: ["Canada", "Mexico"] },
                    { id: "tipo", label: "Facility Type", type: "select", options: ["FARMACIA", "ALMACEN_CENTRAL"] }
                ]
            },
            { 
                title: "1.2 EMPLOYEE", tableName: "EMPLEADO", pks: ["id_empleado"],
                fields: [
                    { id: "id_empleado", label: "Employee ID", type: "text" },
                    { id: "nombre_completo", label: "Full Name", type: "text" },
                    { id: "puesto", label: "Job Title", type: "text" },
                    { id: "id_sucursal", label: "Assigned Branch", type: "fk", dsKey: "sucursales" },
                    { id: "activo", label: "Active Status", type: "checkbox" }
                ]
            },
            { 
                title: "1.3 CUSTOMER", tableName: "CLIENTE", pks: ["id_cliente"],
                fields: [
                    { id: "id_cliente", label: "Customer ID", type: "text" },
                    { id: "nombre_completo", label: "Customer Name", type: "text" },
                    { id: "curp", label: "Government ID (CURP)", type: "text" },
                    { id: "fecha_nacimiento", label: "Date of Birth", type: "date" },
                    { id: "email", label: "Email Address", type: "text" },
                    { id: "id_sucursal_registro", label: "Home Branch", type: "fk", dsKey: "sucursales" }
                ]
            },
            { 
                title: "1.4 LOGISTICS UNIT", tableName: "UNIDAD_LOGISTICA", pks: ["id_unidad"],
                fields: [
                    { id: "id_unidad", label: "Vehicle ID", type: "text" },
                    { id: "matricula", label: "License Plate", type: "text" },
                    { id: "capacidad_kg", label: "Load Capacity (KG)", type: "number-dec" }
                ]
            }
        ]
    },
    {
        title: "2. PRODUCTS & INVENTORY",
        submodules: [
            { 
                title: "2.1 PRODUCT", tableName: "PRODUCTO", pks: ["id_producto"],
                fields: [
                    { id: "id_producto", label: "Product ID", type: "text" },
                    { id: "sku", label: "SKU", type: "text" },
                    { id: "nombre", label: "Product Name", type: "text" },
                    { id: "descripcion", label: "Description", type: "text" },
                    { id: "precio_base", label: "Unit Price", type: "number-dec" },
                    { id: "requiere_receta", label: "Requires Prescription", type: "checkbox" }
                ]
            },
            { 
                title: "2.2 INVENTORY", tableName: "INVENTARIO", pks: ["id_sucursal", "id_producto"],
                fields: [
                    { id: "id_sucursal", label: "Sucursal", type: "fk", dsKey: "sucursales" },
                    { id: "id_producto", label: "Producto", type: "fk", dsKey: "productos" },
                    { id: "cantidad", label: "Current Stock", type: "number" },
                    { id: "stock_minimo", label: "Minimum Threshold", type: "number" }
                ]
            }
        ]
    },
    {
        title: "3. SALES & PAYMENTS MODULE",
        submodules: [
            { 
                title: "3.1 SALE", tableName: "VENTA", pks: ["id_venta"],
                fields: [
                    { id: "id_venta", label: "Sale ID", type: "text" },
                    { id: "id_cliente", label: "Cliente", type: "fk", dsKey: "clientes" },
                    { id: "id_empleado", label: "Salesperson", type: "fk", dsKey: "empleados" },
                    { id: "fecha_venta", label: "Transaction Date & Time", type: "timestamp" },
                    { id: "estatus", label: "Sale Status", type: "select", options: ["PENDIENTE", "PAGADA", "ENTREGADA", "CANCELADA"] },
                    { id: "monto_total", label: "Total Amount", type: "number-dec" }
                ]
            },
            { 
                title: "3.2 SALE DETAIL", tableName: "DETALLE_VENTA", pks: ["id_venta", "id_producto"],
                fields: [
                    { id: "id_venta", label: "Sale ID", type: "fk", dsKey: "ventas" },
                    { id: "id_producto", label: "Producto", type: "fk", dsKey: "productos" },
                    { id: "cantidad", label: "Units Sold", type: "number" },
                    { id: "precio_unitario", label: "Applied Price", type: "number-dec" },
                    { id: "subtotal", label: "Line Subtotal", type: "number-dec" }
                ]
            },
            { 
                title: "3.3 PAYMENT", tableName: "PAGO", pks: ["id_pago"],
                fields: [
                    { id: "id_pago", label: "Payment ID", type: "text" },
                    { id: "id_venta", label: "Sale ID", type: "fk", dsKey: "ventas" },
                    { id: "fecha_pago", label: "Payment Date & Time", type: "timestamp" },
                    { id: "monto", label: "Amount Paid", type: "number-dec" },
                    { id: "metodo_pago", label: "Payment Method", type: "select", options: ["EFECTIVO", "TARJETA_CREDITO", "TARJETA_DEBITO", "TRANSFERENCIA", "CUPON", "PUNTOS"] }
                ]
            }
        ]
    },
    {
        title: "4. MÓDULO DE DEVOLUCIONES",
        submodules: [
            { 
                title: "4.1 DEVOLUCIÓN", tableName: "DEVOLUCION", pks: ["id_devolucion"],
                fields: [
                    { id: "id_devolucion", label: "Folio de Devolucion", type: "text" },
                    { id: "id_venta", label: "Folio de Venta Original", type: "fk", dsKey: "ventas" },
                    { id: "id_empleado_autoriza", label: "Autorizado Por", type: "fk", dsKey: "empleados" },
                    { id: "fecha_devolucion", label: "Fecha Retorno", type: "timestamp" },
                    { id: "motivo", label: "Razon Devolucion", type: "text" },
                    { id: "estatus", label: "Estado Solicitud", type: "select", options: ["SOLICITADA", "APROBADA", "RECHAZADA"] }
                ]
            },
            { 
                title: "4.2 DETALLE DEVOLUCIÓN", tableName: "DETALLE_DEVOLUCION", pks: ["id_devolucion", "id_producto"],
                fields: [
                    { id: "id_devolucion", label: "Folio de Devolución", type: "fk", dsKey: "devoluciones" },
                    { id: "id_producto", label: "Producto", type: "fk", dsKey: "productos" },
                    { id: "cantidad", label: "Unidades Devueltas", type: "number" }
                ]
            }
        ]
    },
    {
        title: "5. LOGÍSTICA",
        submodules: [
            { 
                title: "5.1 TRASPASO", tableName: "TRASPASO", pks: ["id_traspaso"],
                fields: [
                    { id: "id_traspaso", label: "Folio de Traspaso", type: "text" },
                    { id: "id_sucursal_origen", label: "Sucursal Remitente", type: "fk", dsKey: "sucursales" },
                    { id: "id_sucursal_destino", label: "Sucursal Destino", type: "fk", dsKey: "sucursales" },
                    { id: "id_unidad", label: "Transporte Asignado", type: "fk", dsKey: "unidades" },
                    { id: "id_empleado_responsable", label: "Chofer O Encargado", type: "fk", dsKey: "empleados" },
                    { id: "fecha_salida", label: "Fecha Despacho", type: "timestamp" },
                    { id: "fecha_recepcion", label: "Fecha Entrega", type: "timestamp" },
                    { id: "estatus", label: "Estado Envio", type: "select", options: ["PREPARACION", "TRANSITO", "RECIBIDO", "INCIDENCIA"] }
                ]
            },
            { 
                title: "5.2 DETALLE TRASPASO", tableName: "DETALLE_TRASPASO", pks: ["id_traspaso", "id_producto"],
                fields: [
                    { id: "id_traspaso", label: "Folio Traspaso", type: "fk", dsKey: "traspasos" }, 
                    { id: "id_producto", label: "Producto", type: "fk", dsKey: "productos" },
                    { id: "cantidad_enviada", label: "Unidades Salida", type: "number" },
                    { id: "cantidad_recibida", label: "Unidades Recibidas", type: "number" }
                ]
            }
        ]
    }
];

let currentState = { mainIndex: 0, subIndex: 0, action: 'ALTAS' };

const mainTabsContainer = document.getElementById('mainTabsContainer');
const subTabsContainer = document.getElementById('subTabsContainer');
const formContainer = document.getElementById('formContainer');

function initApp() {
    cargarCatalogos().then(() => {
        renderMainTabs();
        updateView();
    });
}

function renderMainTabs() {
    mainTabsContainer.innerHTML = systemStructure.map((module, index) => `
        <button class="tab-btn ${index === currentState.mainIndex ? 'active' : ''}" 
                onclick="setMainTab(${index})">${module.title}</button>
    `).join('');
}

function renderSubTabs() {
    const currentModule = systemStructure[currentState.mainIndex];
    subTabsContainer.innerHTML = currentModule.submodules.map((sub, index) => `
        <button class="sub-tab-btn ${index === currentState.subIndex ? 'active' : ''}" 
                onclick="setSubTab(${index})">${sub.title}</button>
    `).join('');
}

// =========================================
// RENDERIZADO DE TABLA Y BARRA SUPERIOR
// =========================================
async function renderDataTable(submodule, searchQuery = '') {
    formContainer.innerHTML = `
        <div class="form-container full-width">
            <h3>Gestión de ${submodule.title}</h3>
            
            <div class="top-bar">
                <div class="search-box">
                    <span class="search-icon">🔍</span>
                    <input type="text" id="searchInput" class="form-control" placeholder="Buscar registros por coincidencia..." value="${searchQuery}">
                </div>
                <button class="btn btn-primary" onclick="abrirModal('ALTAS')">
                    + Agregar Nuevo
                </button>
            </div>

            <div id="tableContent" style="padding: 2rem; text-align: center; color: var(--text-light);">
                Sincronizando con la base de datos...
            </div>
        </div>
    `;

    const searchInput = document.getElementById('searchInput');
    let timeoutId;
    searchInput.addEventListener('input', (e) => {
        clearTimeout(timeoutId);
        timeoutId = setTimeout(() => renderDataTable(submodule, e.target.value), 400);
    });
    if (searchQuery) searchInput.focus();

    try {
        const url = searchQuery ? `${API_BASE_URL}/crud/${submodule.tableName}?q=${searchQuery}` : `${API_BASE_URL}/crud/${submodule.tableName}`;
        const res = await fetch(url);
        const data = await res.json();
        
        window.currentTableData = data; 

        if (data.length === 0) {
            document.getElementById('tableContent').innerHTML = '<p>No records found en esta tabla.</p>';
            return;
        }

        const headersHTML = submodule.fields.map(f => `<th>${f.label}</th>`).join('') + `<th style="text-align:center;">ACCIONES</th>`;
        
        const rowsHTML = data.map((row, index) => {
            let esDeCanada = false;
            const idSucursal = row['id_sucursal'] || row['id_sucursal_origen'] || row['id_sucursal_registro'];
            
            if (idSucursal && realDatabase.sucursales) {
                const sucursalData = realDatabase.sucursales.find(s => s.id == idSucursal);
                if (sucursalData && (sucursalData.texto.toLowerCase().includes('canadá') || sucursalData.texto.toLowerCase().includes('canada'))) {
                    esDeCanada = true;
                }
            }
            const rowClass = esDeCanada ? 'fila-canada' : '';

            const cellsHTML = submodule.fields.map(f => {
                let rawValue = row[f.id.toLowerCase()];
                if (rawValue === undefined || rawValue === null) rawValue = '';
                let displayValue = rawValue;
                if (f.type === 'fk' && f.dataSource) {
                    const match = f.dataSource.find(i => i.id == rawValue);
                    if (match) displayValue = match.texto;
                } else if (f.type === 'checkbox') {
                    displayValue = rawValue === 'S' ? 'Sí' : 'No';
                }
                return `<td>${displayValue}</td>`;
            }).join('');
            
            const accionesHTML = `
                <td style="text-align:center;">
                    <div class="action-icons" style="justify-content: center;">
                        <button class="icon-btn icon-edit" onclick="abrirModal('EDITAR', ${index})" title="Edit Registro">✏️</button>
                        <button class="icon-btn icon-delete" onclick="eliminarRegistroDirecto(${index})" title="Delete Registro">🗑️</button>
                    </div>
                </td>
            `;
            return `<tr class="${rowClass}">${cellsHTML}${accionesHTML}</tr>`;
        }).join('');

        document.getElementById('tableContent').outerHTML = `
            <div class="table-responsive">
                <table class="data-table">
                    <thead><tr>${headersHTML}</tr></thead>
                    <tbody>${rowsHTML}</tbody>
                </table>
            </div>
        `;
    } catch (error) {
        document.getElementById('tableContent').innerHTML = `<p style="color: var(--danger);">Error while consultar la base de datos.</p>`;
    }
}

// =========================================
// LÓGICA DEL MODAL Y ELIMINACIÓN DIRECTA
// =========================================
function abrirModal(modo, rowIndex = null) {
    const modal = document.getElementById('crudModal');
    const container = document.getElementById('modalFormContainer');
    const currentSubmodule = systemStructure[currentState.mainIndex].submodules[currentState.subIndex];
    
    currentState.action = modo;
    
    const fieldsHTML = currentSubmodule.fields.map(f => generateFieldHTML(f)).join('');
    
    container.innerHTML = `
        <h3 style="color: var(--primary-dark); margin-bottom: 1.5rem; border-bottom: 2px solid var(--secondary); padding-bottom: 0.5rem;">
            ${modo === 'ALTAS' ? 'New Record' : 'Edit Registro'} > ${currentSubmodule.title}
        </h3>
        <form id="mainForm">
            <div class="form-grid">
                ${fieldsHTML}
                <div class="form-actions" style="grid-column: 1 / -1; margin-top: 1.5rem;">
                    <button type="submit" class="btn btn-primary">Save Cambios</button>
                    <button type="button" class="btn btn-secondary" onclick="cerrarModal()">Cancel</button>
                </div>
            </div>
        </form>
    `;

    currentSubmodule.fields.forEach(field => {
        if (field.type === 'fk') {
            const fieldContainer = container.querySelector(`[data-field-id="${field.id}"]`);
            if (fieldContainer) setupAutocomplete(field, fieldContainer);
        }
    });

    if (modo === 'EDITAR' && rowIndex !== null) {
        const record = window.currentTableData[rowIndex];
        cargarDatosAlFormulario(record, currentSubmodule);
    }

    modal.classList.add('show');
}

function cerrarModal() {
    document.getElementById('crudModal').classList.remove('show');
}

async function eliminarRegistroDirecto(rowIndex) {
    if(!confirm('¿Estás seguro de eliminar este registro? Esta acción es irreversible.')) return;
    
    const sub = systemStructure[currentState.mainIndex].submodules[currentState.subIndex];
    const record = window.currentTableData[rowIndex];
    const vals = sub.pks.map(pk => record[pk.toLowerCase()]); 
    
    try {
        const url = `${API_BASE_URL}/crud/${sub.tableName}?pks=${sub.pks.join(',')}&vals=${vals.join(',')}`;
        const res = await fetch(url, { method: 'DELETE' });
        const data = await res.json();
        
        if(res.ok) {
            alert("Eliminado correctamente.");
            await cargarCatalogos();
            updateView(); 
        } else {
            alert("Error de BD:\n" + data.error);
        }
    } catch(e) { alert("Error de red al eliminar."); }
}

// =========================================
// GENERADOR DE HTML Y AUTOCOMPLETADOS
// =========================================
function generateFieldHTML(field) {
    let inputHTML = '';
    if (field.type === 'fk') {
        inputHTML = `
            <div class="autocomplete-wrapper">
                <input type="text" class="form-control autocomplete-input" id="input_${field.id}" placeholder="Seleccione o busque opción..." autocomplete="off">
                <span class="autocomplete-icon">▼</span>
                <input type="hidden" name="${field.id}" id="hidden_${field.id}">
                <div class="autocomplete-results" id="results_${field.id}"></div>
            </div>
        `;
    } else if (field.type === 'select') {
        const optionsHTML = field.options.map(opt => `<option value="${opt}">${opt}</option>`).join('');
        inputHTML = `
            <select class="form-control" name="${field.id}" id="${field.id}">
                <option value="">-- Seleccionar Opción --</option>
                ${optionsHTML}
            </select>
        `;
    } else {
         switch(field.type) {
            case 'text': inputHTML = `<input type="text" class="form-control" name="${field.id}">`; break;
            case 'number': inputHTML = `<input type="number" class="form-control" name="${field.id}" placeholder="0">`; break;
            case 'number-dec': inputHTML = `<input type="number" step="0.01" class="form-control" name="${field.id}" placeholder="0.00">`; break;
            case 'checkbox':
                inputHTML = `
                    <div class="checkbox-wrapper">
                        <input type="checkbox" id="${field.id}" name="${field.id}" value="S">
                        <label for="${field.id}">Sí / Activo</label>
                    </div>`;
                break;
            case 'date': inputHTML = `<input type="date" class="form-control" name="${field.id}">`; break;
            case 'timestamp': inputHTML = `<input type="datetime-local" class="form-control" name="${field.id}">`; break;
        }
    }
    return `<div class="form-group" data-field-id="${field.id}" data-field-type="${field.type}"><label for="${field.id}">${field.label}</label>${inputHTML}</div>`;
}

function setupAutocomplete(field, container) {
    const input = container.querySelector(`#input_${field.id}`);
    const hiddenInput = container.querySelector(`#hidden_${field.id}`);
    const resultsContainer = container.querySelector(`#results_${field.id}`);
    let data = field.dataSource || [];

    function renderList(filterText) {
        resultsContainer.innerHTML = '';
        const filteredData = data.filter(item => item.texto.toLowerCase().includes(filterText.toLowerCase()));

        if (filteredData.length > 0) {
            filteredData.forEach(item => {
                const div = document.createElement('div');
                div.classList.add('autocomplete-item');
                div.textContent = item.texto;
                
                div.addEventListener('click', function(e) {
                    e.stopPropagation(); 
                    input.value = item.texto;
                    hiddenInput.value = item.id;
                    resultsContainer.classList.remove('show');
                });
                resultsContainer.appendChild(div);
            });
            resultsContainer.classList.add('show');
        }
    }

    input.addEventListener('input', function() {
        renderList(this.value);
        if(this.value.trim() === '') hiddenInput.value = '';
    });
    input.addEventListener('focus', function() { renderList(this.value); });
    input.addEventListener('click', function() { renderList(this.value); });
    document.addEventListener('click', function(e) {
        if (!container.contains(e.target)) resultsContainer.classList.remove('show');
    });
}

function cargarDatosAlFormulario(record, submodule) {
    submodule.fields.forEach(f => {
        const val = record[f.id.toLowerCase()];
        if(val !== undefined && val !== null) {
            const el = document.querySelector(`[name="${f.id}"]`);
            if(el) {
                if(f.type === 'checkbox') el.checked = (val === 'S');
                else el.value = val;
                
                if(f.type === 'fk' && f.dataSource) {
                    const match = f.dataSource.find(i => i.id == val);
                    if(match) document.getElementById(`input_${f.id}`).value = match.texto;
                }
            }
        }
    });
}

// =========================================
// EVENTO CENTRAL: POST Y PUT 
// =========================================
document.addEventListener('submit', async function(e) {
    if (e.target && e.target.id === 'mainForm') {
        e.preventDefault(); 
        
        const formData = new FormData(e.target);
        const dataPayload = Object.fromEntries(formData.entries());
        
        e.target.querySelectorAll('input[type="checkbox"]').forEach(cb => {
            dataPayload[cb.name] = cb.checked ? 'S' : 'N'; 
        });

        const sub = systemStructure[currentState.mainIndex].submodules[currentState.subIndex];
        let method = currentState.action === 'ALTAS' ? 'POST' : 'PUT';
        let url = `${API_BASE_URL}/crud/${sub.tableName}`;
        
        if (method === 'PUT') {
            url += `?pks=${sub.pks.join(',')}`;
        }

        try {
            const respuesta = await fetch(url, {
                method: method,
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(dataPayload)
            });
            
            const resultado = await respuesta.json();
            if (respuesta.ok) {
                alert(resultado.mensaje);
                cerrarModal(); 
                await cargarCatalogos(); 
                updateView(); 
            } else {
                alert("Error de BD:\n" + resultado.error);
            }
        } catch (error) {
            alert("Error de red: Verifica que Flask esté encendido.");
        }
    }
});

// Navegación Básica
function setMainTab(index) {
    currentState.mainIndex = index;
    currentState.subIndex = 0;
    updateView();
    renderMainTabs();
}

function setSubTab(index) { currentState.subIndex = index; updateView(); }

function updateView() {
    renderSubTabs();
    renderDataTable(systemStructure[currentState.mainIndex].submodules[currentState.subIndex]);
}

// Iniciar App
initApp();