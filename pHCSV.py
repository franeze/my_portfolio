import tkinter as tk
from tkinter import ttk
import random
import time
import os
import csv
from datetime import datetime
from tkinter import messagebox, filedialog
import matplotlib.pyplot as plt
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg

class pHMeterApp:
    def __init__(self, root):
        self.root = root
        self.root.title("New File - random pH Meter app")
        self.root.geometry("800x600")
        self.archivo_abierto = None
        self.borrar_nuevo = True
        self.loop = False
        self.archivo_medidas_automatico = f"measurements_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv"
        self.measurements = []  # List to store the pH measurements

        # Setup UI components
        self.setup_ui()

    def setup_ui(self):
        # Frames
        bottomframe = tk.Frame(self.root)
        bottomframe.pack(side=tk.BOTTOM, anchor=tk.N)

        leftframe = tk.Frame(self.root)
        leftframe.pack(side=tk.LEFT, anchor=tk.N)

        # Variables
        self.var_1 = tk.StringVar()
        self.var_2 = tk.StringVar()
        self.var_3 = tk.StringVar()

        # Labels and Entries
        self.create_label_entry(leftframe, "Enter the interval in minutes for pH measurements", self.var_2)
        self.create_label_entry(leftframe, "Enter the pH value to stop injecting CO₂", self.var_1)
        self.create_label_entry(leftframe, "Enter the pH value to start injecting CO₂", self.var_3)

        # Buttons
        self.create_button(leftframe, "Start", self.comenzar)
        self.create_button(leftframe, "Stop Measurement", self.detener)
        self.create_button(leftframe, "Exit", self.salir)

        # Treeview
        self.setup_treeview()

        # Plot
        self.setup_plot()

        # Menu
        self.setup_menu()

    def create_label_entry(self, frame, text, variable):
        label = tk.Label(frame, text=text, font=("verdana", 12))
        label.pack(padx=10, pady=10)
        entry = tk.Entry(frame, textvariable=variable, font=("verdana", 12), justify=tk.CENTER)
        entry.pack(padx=50)

    def create_button(self, frame, text, command):
        button = tk.Button(frame, text=text, command=command, font=("verdana", 12))
        button.pack(padx=120, pady=10)

    def setup_treeview(self):
        columns = ("pH", "Date", "Time")
        self.tree = ttk.Treeview(self.root, columns=columns, show="headings")

        self.tree.column("pH", width=100, anchor="center")
        self.tree.column("Date", width=150, anchor="center")
        self.tree.column("Time", width=100, anchor="center")

        self.tree.heading("pH", text="pH")
        self.tree.heading("Date", text="Date")
        self.tree.heading("Time", text="Time")

        self.tree.pack(padx=10, pady=10, fill=tk.BOTH, expand=True)

        # Configure the table's scrollbar
        scrollbar = ttk.Scrollbar(self.root, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscroll=scrollbar.set)
        scrollbar.pack(side="right", fill="y")

    def setup_plot(self):
        # Create a figure and axis for plotting
        self.fig, self.ax = plt.subplots(figsize=(6, 4), dpi=100)
        self.ax.set_title("pH vs Time")
        self.ax.set_xlabel("Time")
        self.ax.set_ylabel("pH")

        # Create a canvas for the plot and add it to the tkinter window
        self.canvas = FigureCanvasTkAgg(self.fig, master=self.root)
        self.canvas_widget = self.canvas.get_tk_widget()
        self.canvas_widget.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

    def plot_data(self):
        # Clear the previous plot
        self.ax.clear()

        # Update the plot with the last 20 measurements
        if len(self.measurements) > 0:
            last_10 = self.measurements[-10:]
            times = [m[1] for m in last_10]
            ph_values = [m[0] for m in last_10]
            self.ax.plot(times, ph_values, marker='o')
            self.ax.set_title("pH vs Time")
            self.ax.set_xlabel("Time")
            self.ax.set_ylabel("pH")
            self.ax.tick_params(axis='x', rotation=90)

        # Automatically adjust layout to prevent overlap
        self.fig.tight_layout()
        # Redraw the plot
        self.canvas.draw()

    def setup_menu(self):
        mi_menu = tk.Menu(self.root)
        self.root.config(menu=mi_menu)

        menu_archivo = tk.Menu(mi_menu, tearoff=False)
        mi_menu.add_cascade(label="File", menu=menu_archivo)
        menu_archivo.add_command(label="New", command=self.nuevo)
        menu_archivo.add_command(label="Open", command=self.open)
        menu_archivo.add_command(label="Save", command=self.save)
        menu_archivo.add_command(label="Save As", command=self.save_as)
        menu_archivo.add_separator()
        menu_archivo.add_command(label="Exit", command=self.root.quit)

    def autosave(self):
        if self.archivo_abierto:
            try:
                with open(self.archivo_abierto, "w", newline='') as file:
                    writer = csv.writer(file)
                    writer.writerow(["pH", "Date", "Time"])  # Write header
                    for item in self.tree.get_children():
                        writer.writerow(self.tree.item(item)["values"])
                print(f"File saved as {self.archivo_abierto}")  # Debug statement

                # Update the plot with the latest data
                self.plot_data()

            except Exception as e:
                messagebox.showerror("Error", f"Failed to save file: {e}")
        else:
            self.save_as()

    def registrar_ph(self):
        fecha_y_hora = datetime.now()
        año = fecha_y_hora.year
        mes = fecha_y_hora.month
        dia = fecha_y_hora.day
        tiempo = time.strftime('%H:%M:%S')

        if self.borrar_nuevo:
            # Ensure the automatic save file exists before starting measurements
            if not os.path.exists(self.archivo_medidas_automatico):
                self.autosave()

        print("Starting pH measurement.")
        print("Please enter the pH value.")

        try:
            minutos = float(self.var_2.get())
            ph_min = float(self.var_1.get())
            ph_max = float(self.var_3.get())

            # Validate that ph_min is less than ph_max
            if ph_min >= ph_max:
                messagebox.showerror("Input Error", "The minimum pH value should be less than the maximum pH value.")
                return

            segundos = minutos * 60
            milisegundos = int(segundos * 1000)

            # Generate a random pH value within the specified range
            ph = round(random.uniform(ph_min, ph_max), 2)
            print(f"The measured pH value is {ph}")

            if ph >= ph_max:
                print(f"Inject CO₂ because the pH is {ph}.")
            elif ph <= ph_min:
                print(f"No need to inject CO₂ because the pH is {ph}.")
            else:
                print("CO₂ is being adjusted.")

            # Append the measurement to the Treeview table
            self.tree.insert("", "end", values=(ph, f"{dia}/{mes}/{año}", tiempo))

            # Append the measurement to the list
            self.measurements.append((ph, tiempo))

            # Call the automatic save function after recording the measurement
            self.autosave()

            self.borrar_nuevo = False

            if self.loop:
                self.root.after(milisegundos, self.registrar_ph)
            else:
                self.root.title("Stopped... random pH Meter ")

        except ValueError:
            messagebox.showerror("Input Error", "Please enter valid numeric values for the pH range and interval.")

    def comenzar(self):
        self.loop = True
        print("Starting measurement loop.")  # Debug statement
        # Create the CSV file if it doesn't exist
        self.autosave()
        self.registrar_ph()

    def detener(self):
        self.loop = False
        print("Measurement stopped.")  # Debug statement

    def salir(self):
        self.root.quit()

    def nuevo(self):
        if not self.borrar_nuevo:
            self.borrar_nuevo = True
        self.tree.delete(*self.tree.get_children())

    def open(self):
        archivo = filedialog.askopenfilename(defaultextension=".csv", filetypes=[("CSV Files", "*.csv"), ("All Files", "*.*")])
        if archivo:
            self.archivo_abierto = archivo
            self.cargar_archivo()

    def save(self):
        if self.archivo_abierto:
            self.autosave()
        else:
            self.save_as()

    def save_as(self):
        archivo = filedialog.asksaveasfilename(defaultextension=".csv", filetypes=[("CSV Files", "*.csv"), ("All Files", "*.*")])
        if archivo:
            self.archivo_abierto = archivo
            self.autosave()

    def cargar_archivo(self):
        if self.archivo_abierto:
            try:
                with open(self.archivo_abierto, "r") as file:
                    reader = csv.reader(file)
                    next(reader)  # Skip header
                    for row in reader:
                        self.tree.insert("", "end", values=row)
                        self.measurements.append((float(row[0]), row[2]))  # Append to the measurements list
                self.plot_data()  # Plot data after loading
            except Exception as e:
                messagebox.showerror("Error", f"Failed to open file: {e}")

if __name__ == "__main__":
    root = tk.Tk()
    app = pHMeterApp(root)
    root.mainloop()
