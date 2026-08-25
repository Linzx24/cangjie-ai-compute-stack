package task_09_generic_swap

public func swap<T>(pair: (T, T)): (T, T) {
    return (pair[1], pair[0])
}
