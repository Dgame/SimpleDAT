module DAT.Stack;

struct Stack(T) {
public:
	T[] data;
	uint index;
	
	T top() const pure nothrow {
		if (this.index != 0)
			return this.data[this.index - 1];
		
		return T.init;
	}
	
	void push(T val) {
		if (this.data.length > this.index)
			this.data[this.index++] = val;
		else {
			this.index++;
			this.data ~= val;
		}
	}
	
	T pop() {
		T top = this.top();
		
		if (this.index != 0)
			this.index--;
		
		return top;
	}
}