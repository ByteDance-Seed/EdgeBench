# Simple Neural Network (Perceptron)
# Demonstrates: math operations, mutation, pipelines, closures

fn dot(a, b) {
  let mut result = 0
  for i in 0..len(a) {
    result = result + a[i] * b[i]
  }
  result
}

fn sigmoid(x) => 1 / (1 + 2.718 ** (-x))

fn sigmoid_derivative(x) => x * (1 - x)

fn new_perceptron(input_size) {
  # Initialize weights randomly (using simple seed-based approach)
  let mut weights = []
  for i in 0..input_size {
    let w = (((i + 1) * 7 + 3) % 100) / 100.0 - 0.5
    weights = push(weights, w)
  }
  {weights: weights, bias: 0.1, learning_rate: 0.5}
}

fn predict(perceptron, inputs) {
  let weighted_sum = dot(inputs, perceptron.weights) + perceptron.bias
  sigmoid(weighted_sum)
}

fn train_one(perceptron, inputs, target) {
  let output = predict(perceptron, inputs)
  let error = target - output
  let delta = error * sigmoid_derivative(output)

  # Update weights
  let mut new_weights = []
  for i in 0..len(perceptron.weights) {
    let w = perceptron.weights[i] + perceptron.learning_rate * delta * inputs[i]
    new_weights = push(new_weights, w)
  }
  perceptron.weights = new_weights
  perceptron.bias = perceptron.bias + perceptron.learning_rate * delta
  error
}

fn train(perceptron, data, labels, epochs) {
  for epoch in 0..epochs {
    let mut total_error = 0
    for i in 0..len(data) {
      let error = train_one(perceptron, data[i], labels[i])
      total_error = total_error + abs(error)
    }
    if epoch % 200 == 0 {
      print("  Epoch {epoch}: avg error = {total_error / len(data)}")
    }
  }
}

# Train AND gate
print("=== Neural Network: AND Gate ===")
let mut p = new_perceptron(2)

let data = [[0, 0], [0, 1], [1, 0], [1, 1]]
let labels = [0, 0, 0, 1]

train(p, data, labels, 1000)

print("\nResults:")
for i in 0..len(data) {
  let output = predict(p, data[i])
  let rounded = if output > 0.5 { 1 } el { 0 }
  print("  {data[i]} => {rounded} (raw: {output})")
}

# Train OR gate
print("\n=== Neural Network: OR Gate ===")
let mut p2 = new_perceptron(2)
let or_labels = [0, 1, 1, 1]

train(p2, data, or_labels, 1000)

print("\nResults:")
for i in 0..len(data) {
  let output = predict(p2, data[i])
  let rounded = if output > 0.5 { 1 } el { 0 }
  print("  {data[i]} => {rounded} (raw: {output})")
}
