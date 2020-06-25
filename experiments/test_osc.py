from pythonosc.udp_client import SimpleUDPClient

ip = "127.0.0.1"
port = 10679

client = SimpleUDPClient(ip, port)  # Create client

#client.send_message("/Carla_Rack/set_parameter_value", [56, 0.5])   # Send float message
client.send_message("/Carla_Rack/0/set_parameter_value", [59, 0.5])   # Send float message
