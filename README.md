# 🚀 Informe Técnico – Desafío CI/CD (Sesión 5)

**Proyecto:** Pruebas de Rendimiento sobre API Externa (httpbin.org)  
**Autor:** André Abreo  
**Fecha:** Octubre 2025  
**Herramientas:** Apache JMeter 5.6.3 + Docker + Jenkins + GitHub  
**Infraestructura:** VM Ubuntu 24.04 (8 GB RAM, 4 CPU)

---

## 1️⃣ Objetivo del Ejercicio
Implementar una **canalización CI/CD automatizada** para pruebas de rendimiento con:
- Ejecución de **JMeter en contenedor Docker**.
- **Configuración basada en propiedades** (threads, ramp-up, duración, endpoint).
- Validación automática de **SLA/SLO** con script `check.sh` (p95 ≤ 500 ms, Tasa error ≤ 1%).
- **Corte automático del pipeline** cuando las métricas exceden los umbrales.

---

## 2️⃣ Descripción Técnica

### Infraestructura
- **VM Ubuntu 24.04** con Docker y Docker Compose.
- **Contenedores desplegados:** Jenkins, JMeter CLI, Prometheus y Grafana (solo fase inicial).
- Se configuró **Jenkins en Docker** y se conectó con **GitHub** para clonado automático del repositorio.

### Pipeline
- **Archivo Jenkinsfile:** define el flujo completo de CI/CD.
- **Variables configurables:** `threads`, `rampup`, `duration`, `base_url`.
- **Script check.sh:** analiza el archivo `results.jtl` y detiene la ejecución si se violan los SLA.
- **Integración automática:** los resultados y reportes se generan dentro del workspace y se archivan en Jenkins.

---

## 3️⃣ Configuración de Pruebas

| Parámetro | Valor |
|------------|--------|
| Usuarios concurrentes | 50 hilos |
| Duración total | 120 segundos |
| Loops por hilo | 1 |
| Endpoints probados | 4 (GET, DELAY, STATUS, COOKIES) |
| Criterios de validación | p95 ≤ 500 ms, Tasa error ≤ 1% |
| Estrategia | Ejecución continua sin pausas hasta corte SLA |

---

## 4️⃣ Resultados Globales

| Métrica | Valor |
|----------|--------|
| Total de muestras | 200 |
| Promedio (p50 global) | **274 ms** |
| Percentil 95 (p95 global) | **30.002 ms** |
| Error rate total | **69%** |
| Throughput | **1.7 req/s** |
| Código de error predominante | **503 – Service Temporarily Unavailable** |

**Detalle por endpoint:**

| Endpoint | Promedio (ms) | P95 (ms) | Error % | Throughput (req/min) |
|-----------|----------------|-----------|----------|-----------------------|
| 01 - GET | 6.248 | 30.138 | 60% | 25.5 |
| 02 - DELAY | 3.694 | 17.429 | 62% | 26.4 |
| 03 - STATUS | 3.862 | 24.526 | 74% | 27.4 |
| 04 - COOKIES | 4.272 | 30.001 | 82% | 27.9 |
| **TOTAL** | **4.519** | **30.002** | **69.5%** | **1.7/sec** |

---

## 5️⃣ Análisis y Observaciones

- La API **httpbin.org** bajo alta concurrencia mostró una **saturación inmediata**.
- Las respuestas **503 (Service Temporarily Unavailable)** evidencian que el servidor rechaza múltiples solicitudes simultáneas.
- Todos los endpoints **superaron ampliamente los SLA definidos**, provocando el corte del pipeline en validaciones posteriores.
- Se ejecutó una corrida **sin el script de validación activa** para medir el rendimiento bruto de la API, confirmando la degradación de respuesta.
- **Throughput muy bajo (1.7 req/s)** por la latencia y el rechazo de conexiones.
- El plan usó **propiedades dinámicas** (`-Jthreads`, `-Jduration`, `-Jrampup`, `-Jbase_url`) que permiten modificar los escenarios directamente desde el Jenkinsfile sin cambiar el `.jmx`.

---

## 6️⃣ Conclusión Técnica

El desafío fue exitosamente implementado con un **pipeline CI/CD funcional**, conectado a GitHub y con ejecución totalmente automatizada:

✅ VM Ubuntu configurada con Docker y contenedores  
✅ Jenkins desplegado en Docker y vinculado a repositorio remoto  
✅ Pipeline con etapas de build, ejecución, validación y archivado  
✅ Script `check.sh` validando automáticamente SLA/SLO  
✅ Configuración de JMeter parametrizada por propiedades  
✅ Reporte automático y corte de ejecución por incumplimiento de umbrales  

**Conclusión:**  
> La API externa no cumple con los SLA definidos, mostrando una degradación severa bajo carga concurrente.  
> El pipeline CI/CD cumple con los objetivos del desafío, validando, monitoreando y deteniendo automáticamente las ejecuciones cuando se superan los límites de rendimiento.

---

## 7️⃣ Próximos pasos sugeridos
- Optimizar paralelismo de requests (10–20 hilos máximo para APIs públicas).
- Incorporar visualización en Grafana a través de Prometheus JMeter Exporter.
- Ampliar los escenarios con datasets y autenticación simulada.

---

🧩 **Repositorio:** [https://github.com/AndreAbreo/Session5.git]
