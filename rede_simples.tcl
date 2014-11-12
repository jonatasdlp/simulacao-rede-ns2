# Cria uma instância do simulador
set ns [new Simulator]

# Arquivos de saída
set f0 [open out0.tr w]
set f1 [open out1.tr w]
set f2 [open out2.tr w]

# Animação (NAM FILE)
$ns color 1 red
set nf [open anim.nam w]
$ns namtrace-all $nf

# Cria 5 nodos
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]

# Conexão dos 5 nodos
$ns duplex-link $n0 $n3 1Mb 100ms DropTail
$ns duplex-link $n1 $n3 1Mb 100ms DropTail
$ns duplex-link $n2 $n3 1Mb 100ms DropTail
$ns duplex-link $n3 $n4 1Mb 100ms DropTail

# Método para encerrar a simulação
proc finish {} {
  global f0 f1 f2 nf ns

  $ns flush-trace

  close $f0
  close $f1
  close $f2
  close $nf
 
  # Gera os gŕaficos
  exec xgraph out0.tr out1.tr out2.tr -geometry 800x400 &
  exit 0
}


# Procedimento que atribui um agente UDP para um nodo criado anteriormente
proc attach-expoo-traffic { node sink size burst idle rate } {
	
	# Recupera uma instância do simulador
	set ns [Simulator instance]

	# adiciona uma UDP agent ao nodo
	set source [new Agent/UDP]
	$ns attach-agent $node $source

	# Expoo traffic agent e configurações
	set traffic [new Application/Traffic/Exponential]
	$traffic set packetSize_ $size
	$traffic set burst_time_ $burst
	$traffic set idle_time_ $idle
	$traffic set rate_ $rate
        
  $traffic attach-agent $source
	$ns connect $source $sink
	
  return $traffic
}


# Procedimento que grava periodicamente a largura de banda recebida por $sink0/1/2
proc record {} {
  global sink0 sink1 sink2 f0 f1 f2
	
  # Instância do simulador
  set ns [Simulator instance]

	# Define um tempo de espera para o método ser chamado novamente
  set time 0.5
	
  # Bytes recidos dos sink's 0, 1 e 2?
  set bw0 [$sink0 set bytes_]
  set bw1 [$sink1 set bytes_]
  set bw2 [$sink2 set bytes_]
  
	# Calcula a largura da banda (em MBit/s) e escreve nos arquivos
  set now [$ns now]
  puts $f0 "$now [expr $bw0/$time*8/1000000]"
  puts $f1 "$now [expr $bw1/$time*8/1000000]"
  puts $f2 "$now [expr $bw2/$time*8/1000000]"

  # Reseta os valores das fontes
  $sink0 set bytes_ 0
  $sink1 set bytes_ 0
  $sink2 set bytes_ 0

	# Define o método para ser chamado novamente
  $ns at [expr $now+$time] "record"
}

# sinks
set sink0 [new Agent/LossMonitor]
set sink1 [new Agent/LossMonitor]
set sink2 [new Agent/LossMonitor]
$ns attach-agent $n4 $sink0
$ns attach-agent $n4 $sink1
$ns attach-agent $n4 $sink2

# Definição de 3 fontes que vão prover os dados
set source0 [attach-expoo-traffic $n0 $sink0 200 2s 1s 100k]
set source1 [attach-expoo-traffic $n1 $sink1 200 2s 1s 200k]
set source2 [attach-expoo-traffic $n2 $sink2 200 2s 1s 300k]

# Definição do periodo em que os eventos vão acontecer
$ns at 0.0 "record"
$ns at 10.0 "$source0 start"
$ns at 10.0 "$source1 start"
$ns at 10.0 "$source2 start"

$ns at 50.0 "$source0 stop"
$ns at 50.0 "$source1 stop"
$ns at 50.0 "$source2 stop"

$ns at 60.0 "finish"

# Ponto de partida
$ns run
