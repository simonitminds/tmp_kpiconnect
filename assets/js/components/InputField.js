import React from 'react';
import { Component } from 'react';
import _ from 'lodash';

const InputField = ({model, field, labelText, value, opts}) => {
  const labelClass = _.has(opts, 'labelClass') ? opts.labelClass : 'label';
  const labelDisplay = _.has(opts, 'label') ? opts.label : _.capitalize(labelText);
  const type = _.has(opts, 'type') ? opts.type : 'text';
  return (
    <div className="field">
      <label htmlFor={`${model}_${field}`} className={labelClass}>
      {labelDisplay}
      </label>
      <div className="control">
        <input
          type={type}
          name={`${model}[${field}]`}
          id={`${model}_${field}`}
          className="input"
          defaultValue={value}
          autoComplete="off"
        />
      </div>
    </div>
  );
}

export default InputField;
