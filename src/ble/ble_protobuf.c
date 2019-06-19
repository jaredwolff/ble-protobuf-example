/**
 * Copyright (c) 2012 - 2018, Nordic Semiconductor ASA
 * Copyright (c) 2019, Jared Wolff
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form, except as embedded into a Nordic
 *    Semiconductor ASA integrated circuit in a product or a software update for
 *    such product, must reproduce the above copyright notice, this list of
 *    conditions and the following disclaimer in the documentation and/or other
 *    materials provided with the distribution.
 *
 * 3. Neither the name of Nordic Semiconductor ASA nor the names of its
 *    contributors may be used to endorse or promote products derived from this
 *    software without specific prior written permission.
 *
 * 4. This software, with or without modification, must only be used with a
 *    Nordic Semiconductor ASA integrated circuit.
 *
 * 5. Any software provided in binary form under this license must not be reverse
 *    engineered, decompiled, modified and/or disassembled.
 *
 * THIS SOFTWARE IS PROVIDED BY NORDIC SEMICONDUCTOR ASA "AS IS" AND ANY EXPRESS
 * OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY, NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NORDIC SEMICONDUCTOR ASA OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 * GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */
/* Attention!
 * To maintain compliance with Nordic Semiconductor ASA's Bluetooth profile
 * qualification listings, this section of source code must not be modified.
 */
#include "sdk_common.h"
#if NRF_MODULE_ENABLED(BLE_PROTOBUF)
#include "ble_protobuf.h"
#include <string.h>
#include "ble_srv_common.h"
#include "ble_conn_state.h"
#include "pb_decode.h"
#include "command.pb.h"

#define NRF_LOG_MODULE_NAME ble_protobuf
#if BLE_PROTOBUF_CONFIG_LOG_ENABLED
#define NRF_LOG_LEVEL       BLE_PROTOBUF_CONFIG_LOG_LEVEL
#define NRF_LOG_INFO_COLOR  BLE_PROTOBUF_CONFIG_INFO_COLOR
#define NRF_LOG_DEBUG_COLOR BLE_PROTOBUF_CONFIG_DEBUG_COLOR
#else // BLE_PROTOBUF_CONFIG_LOG_ENABLED
#define NRF_LOG_LEVEL       0
#endif // BLE_PROTOBUF_CONFIG_LOG_ENABLED
#include "nrf_log.h"
NRF_LOG_MODULE_REGISTER();

/**@brief Function for handling the Write event.
 *
 * @param[in]   p_protobuf       Battery Service structure.
 * @param[in]   p_ble_evt   Event received from the BLE stack.
 */
static void on_write(ble_protobuf_t * p_protobuf, ble_evt_t const * p_ble_evt)
{

    ble_gatts_evt_write_t const * p_evt_write = &p_ble_evt->evt.gatts_evt.params.write;


    // Handle writning to the value handle
    if ( p_evt_write->handle == p_protobuf->command_handles.value_handle )
    {

        NRF_LOG_INFO("value");

        // Setitng up protocol buffer data
        event evt;

        // Read in buffer
        pb_istream_t istream = pb_istream_from_buffer((pb_byte_t *)p_evt_write->data, p_evt_write->len);

        if (!pb_decode(&istream, event_fields, &evt)) {
            NRF_LOG_ERROR("Unable to decode: %s", PB_GET_ERROR(&istream));
        return;
    }

        // TODO: Validate code
        // TODO: Check type
        // TODO: if all valid, append message with a return value
        // TODO: encode value
        // TODO: save to char
        // TODO: also push to notification

    }

    // Handling of enabling notifications
    if (    (p_evt_write->handle == p_protobuf->command_handles.cccd_handle)
        &&  (p_evt_write->len == 2))
    {
        NRF_LOG_INFO("cccd");

        if (!p_protobuf->is_notification_supported)
        {
            return;
        }

        if (p_protobuf->evt_handler == NULL)
        {
            return;
        }

        ble_protobuf_evt_t evt;

        if (ble_srv_is_notification_enabled(p_evt_write->data))
        {
            evt.evt_type = BLE_PROTOBUF_EVT_NOTIFICATION_ENABLED;
        }
        else
        {
            evt.evt_type = BLE_PROTOBUF_EVT_NOTIFICATION_DISABLED;
        }
        evt.conn_handle = p_ble_evt->evt.gatts_evt.conn_handle;

        // CCCD written, call application event handler.
        p_protobuf->evt_handler(p_protobuf, &evt);
    }
}


void ble_protobuf_on_ble_evt(ble_evt_t const * p_ble_evt, void * p_context)
{
    if ((p_context == NULL) || (p_ble_evt == NULL))
    {
        return;
    }

    ble_protobuf_t * p_protobuf = (ble_protobuf_t *)p_context;

    switch (p_ble_evt->header.evt_id)
    {
        case BLE_GATTS_EVT_WRITE:
            on_write(p_protobuf, p_ble_evt);
            break;

        default:
            // No implementation needed.
            break;
    }
}


/**@brief Function for adding the Battery Level characteristic.
 *
 * @param[in]   p_protobuf        Battery Service structure.
 * @param[in]   p_protobuf_init   Information needed to initialize the service.
 *
 * @return      NRF_SUCCESS on success, otherwise an error code.
 */
static ret_code_t command_char_add(ble_protobuf_t * p_protobuf, const ble_protobuf_init_t * p_protobuf_init)
{
    ret_code_t             err_code;
    ble_add_char_params_t  add_char_params;
    ble_add_descr_params_t add_descr_params;
    uint8_t                init_len;
    uint8_t                encoded_report_ref[BLE_SRV_ENCODED_REPORT_REF_LEN];

    memset(&add_char_params, 0, sizeof(add_char_params));
    add_char_params.uuid              = PROTOBUF_UUID_CONFIG_CHAR;
    add_char_params.max_len           = _event_event_type_MAX;
    add_char_params.init_len          = 0;
    add_char_params.p_init_value      = NULL;
    add_char_params.char_props.notify = p_protobuf->is_notification_supported;
    add_char_params.char_props.read   = 1;
    add_char_params.cccd_write_access = p_protobuf_init->bl_cccd_wr_sec;
    add_char_params.read_access       = p_protobuf_init->bl_rd_sec;

    err_code = characteristic_add(p_protobuf->service_handle,
                                  &add_char_params,
                                  &(p_protobuf->command_handles));
    if (err_code != NRF_SUCCESS)
    {
        return err_code;
    }

    if (p_protobuf_init->p_report_ref != NULL)
    {
        // Add Report Reference descriptor
        init_len = ble_srv_report_ref_encode(encoded_report_ref, p_protobuf_init->p_report_ref);

        memset(&add_descr_params, 0, sizeof(add_descr_params));
        add_descr_params.uuid        = BLE_UUID_REPORT_REF_DESCR;
        add_descr_params.read_access = p_protobuf_init->bl_report_rd_sec;
        add_descr_params.init_len    = init_len;
        add_descr_params.max_len     = add_descr_params.init_len;
        add_descr_params.p_value     = encoded_report_ref;

        err_code = descriptor_add(p_protobuf->command_handles.value_handle,
                                  &add_descr_params,
                                  &p_protobuf->report_ref_handle);
        return err_code;
    }
    else
    {
        p_protobuf->report_ref_handle = BLE_GATT_HANDLE_INVALID;
    }

    return NRF_SUCCESS;
}


ret_code_t ble_protobuf_init(ble_protobuf_t * p_protobuf, const ble_protobuf_init_t * p_protobuf_init)
{
    if (p_protobuf == NULL || p_protobuf_init == NULL)
    {
        return NRF_ERROR_NULL;
    }

    ret_code_t err_code;
    ble_uuid_t ble_uuid;
    ble_uuid128_t base_uuid = {PROTOBUF_UUID_BASE};

    // Initialize service structure
    p_protobuf->evt_handler               = p_protobuf_init->evt_handler;
    p_protobuf->is_notification_supported = p_protobuf_init->support_notification;

    // Add service
    err_code = sd_ble_uuid_vs_add(&base_uuid, &p_protobuf->uuid_type);
    VERIFY_SUCCESS(err_code);

    ble_uuid.type = p_protobuf->uuid_type;
    ble_uuid.uuid = PROTOBUF_UUID_SERVICE;

    err_code = sd_ble_gatts_service_add(BLE_GATTS_SRVC_TYPE_PRIMARY, &ble_uuid, &p_protobuf->service_handle);
    VERIFY_SUCCESS(err_code);

    // Add battery level characteristic
    err_code = command_char_add(p_protobuf, p_protobuf_init);
    return err_code;
}

// TODO: setup reply using notification, also write value using protobuf

/**@brief Function for sending notifications with the Battery Level characteristic.
 *
 * @param[in]   p_hvx_params Pointer to structure with notification data.
 * @param[in]   conn_handle  Connection handle.
 *
 * @return      NRF_SUCCESS on success, otherwise an error code.
 */
static ret_code_t notification_send(ble_gatts_hvx_params_t * const p_hvx_params,
                                            uint16_t                       conn_handle)
{
    ret_code_t err_code = sd_ble_gatts_hvx(conn_handle, p_hvx_params);
    if (err_code == NRF_SUCCESS)
    {
        NRF_LOG_INFO("Battery notification has been sent using conn_handle: 0x%04X", conn_handle);
    }
    else
    {
        NRF_LOG_DEBUG("Error: 0x%08X while sending notification with conn_handle: 0x%04X",
                      err_code,
                      conn_handle);
    }
    return err_code;
}

#endif // NRF_MODULE_ENABLED(BLE_PROTOBUF)
