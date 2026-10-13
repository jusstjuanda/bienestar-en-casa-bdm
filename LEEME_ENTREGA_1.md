# Entrega 1 — Modelo lógico "Bienestar en Casa" (13/10/2026)

## Archivos
| Archivo | Para qué |
|---|---|
| `bienestar_en_casa.mwb` | **Modelo de MySQL Workbench** (el que se entrega y se sigue editando) |
| `bienestar_en_casa_EER.png` | Imagen del diagrama EER, con colores por zona |
| `bienestar_en_casa.sql` | Esquema MySQL 8 (14 tablas, PK/FK/UK/CHECK); es la fuente en texto |
| `modelo_logico.html` | Versión alternativa del diagrama (abrir en el navegador) |

Colores: azul = usuarios y acceso · ámbar = disponibilidad y cobertura · verde = catálogo · morado = solicitudes y reservas.

## Cómo continuar el trabajo (compañeros)
1. Instalar **MySQL Workbench 8.0** (gratis; ojo: la 26.x ya NO trae modelador, usar 8.0.x).
   `winget install --id Oracle.MySQLWorkbench --version 8.0.47`
2. Clonar el repo y abrir `bienestar_en_casa.mwb` con doble clic (o `File > Open Model`).
3. Editar el diagrama → `Ctrl+S`.
4. Subir los cambios:
   ```bash
   git pull
   git add -A
   git commit -m "describe el cambio"
   git push
   ```

**Regla de oro:** el `.mwb` es un archivo comprimido y Git NO puede fusionarlo. Solo una persona
a la vez debe editarlo: avisen en el grupo antes ("edito el modelo") y hagan `git pull` antes de abrirlo.
Si dos personas lo cambian a la vez, gana el último push y se pierde el otro.

Para cambios pequeños en paralelo, editen el `.sql` (sí se fusiona) y regeneren el modelo con
`File > Import > Reverse Engineer MySQL Create Script…`.

## Tablas (14)
| Tabla | Para qué |
|---|---|
| usuario, cliente, proveedor | Supertipo `usuario` (correo único + hash) con subtipos 1:1 |
| direccion_cliente | Direcciones del cliente; `es_principal` marca la principal |
| zona_atencion | Ciudades/barrios orientativos del proveedor (sin geografía ni distancias) |
| categoria_servicio, servicio | Catálogo con precio, duración, estado ACTIVO/INACTIVO |
| recurso_multimedia | Fotos y videos de referencia del servicio |
| insumo, servicio_insumo | Productos/insumos/equipos (N:M con servicio) |
| horario_disponibilidad | Día de semana + hora inicio/fin |
| periodo_no_disponible | Fechas/periodos bloqueados |
| solicitud_reserva | Solicitud/reserva con copia de nombre, precio y duración |
| recuperacion_contrasena | Código o enlace de un solo uso, con vigencia e invalidación |

## Decisiones de diseño (para la sustentación)
- **Instantánea del servicio:** `nombre_servicio`, `precio_servicio`, `duracion_min` se copian en la solicitud.
- **Estados:** PENDIENTE → ACEPTADA | RECHAZADA | SUGERIDA; SUGERIDA → ACEPTADA | CANCELADA;
  ACEPTADA → COMPLETADA | CANCELADA. Sin historial de cambios (el enunciado no lo pide).
  CHECK: motivo obligatorio si RECHAZADA/CANCELADA; propuesta obligatoria si SUGERIDA.
- **Periodo ocupado:** `fecha_hora_fin` es columna generada = inicio + duración (base del cruce de reservas).
- **Sin `id_proveedor` en la solicitud:** se obtiene por `servicio.id_proveedor` (3FN).
- **Dirección de la solicitud:** copia textual + `id_direccion` opcional.
- **Sin datos clínicos** y contraseñas/tokens solo como hash.

## Reglas que van como triggers en la Entrega 2
1. No cruce de reservas ACEPTADAS del mismo proveedor (al aceptar y al aceptar la sugerida).
2. Verificar horario y periodos no disponibles antes de confirmar.
3. Una sola dirección principal por cliente.
4. Transiciones de estado válidas.
5. Invalidar solicitudes de recuperación anteriores al crear una nueva.
6. `usuario.tipo_usuario` coherente con la tabla subtipo.
