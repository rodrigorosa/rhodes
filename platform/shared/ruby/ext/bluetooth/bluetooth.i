/* signature.i */
%module RhoBluetooth
%{
extern int rho_bluetooth_is_bluetooth_available();
extern void rho_bluetooth_off_bluetooth();
extern void rho_bluetooth_set_device_name(const char* device_name);
extern VALUE rho_bluetooth_get_device_name();
extern const char* rho_bluetooth_get_last_error();
extern const char* rho_bluetooth_create_session(const char* role, const char* callback_url); 

extern const char* rho_bluetooth_create_custom_server_session(const char* client_name, const char* callback_url, int accept_any_device);
extern const char* rho_bluetooth_create_custom_client_session(const char* server_name, const char* callback_url);
extern const char* rho_bluetooth_stop_current_connection_process();


extern void rho_bluetooth_session_set_callback(const char* connected_device_name, const char* callback_url);
extern void rho_bluetooth_session_disconnect(const char* connected_device_name);
extern int rho_bluetooth_session_get_status(const char* connected_device_name);
extern VALUE rho_bluetooth_session_read_string(const char* connected_device_name);
extern void rho_bluetooth_session_write_string(const char* connected_device_name, const char* str);
extern VALUE rho_bluetooth_session_read_data(const char* connected_device_name);
extern void rho_bluetooth_session_write_data(const char* connected_device_name, VALUE data);


#define is_bluetooth_available rho_bluetooth_is_bluetooth_available
#define off_bluetooth rho_bluetooth_off_bluetooth
#define set_device_name rho_bluetooth_set_device_name
#define get_device_name rho_bluetooth_get_device_name
#define get_last_error rho_bluetooth_get_last_error
#define create_session rho_bluetooth_create_session

#define create_custom_server_session rho_bluetooth_create_custom_server_session
#define create_custom_client_session rho_bluetooth_create_custom_client_session
#define stop_current_connection_process rho_bluetooth_stop_current_connection_process


#define session_set_callback rho_bluetooth_session_set_callback
#define session_disconnect rho_bluetooth_session_disconnect
#define session_get_status rho_bluetooth_session_get_status
#define session_read_string rho_bluetooth_session_read_string
#define session_write_string rho_bluetooth_session_write_string
#define session_read_data rho_bluetooth_session_read_data
#define session_write_data rho_bluetooth_session_write_data

#if !defined(bool)
#define bool int
#define true  1
#define false 0
#endif

%}

extern int is_bluetooth_available();
extern void off_bluetooth();
extern void set_device_name(const char* device_name);
extern VALUE get_device_name();
extern const char* get_last_error();
extern const char* create_session(const char* role, const char* callback_url); 

extern const char* create_custom_server_session(const char* client_name, const char* callback_url, int accept_any_device);
extern const char* create_custom_client_session(const char* server_name, const char* callback_url);
extern const char* stop_current_connection_process();

extern void session_set_callback(const char* connected_device_name, const char* callback_url);
extern void session_disconnect(const char* connected_device_name);
extern int session_get_status(const char* connected_device_name);
extern VALUE session_read_string(const char* connected_device_name);
extern void session_write_string(const char* connected_device_name, const char* str);
extern VALUE session_read_data(const char* connected_device_name);
extern void session_write_data(const char* connected_device_name, VALUE data);
